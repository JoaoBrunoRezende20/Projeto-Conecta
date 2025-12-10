import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_border, color: Colors.red, size: 18),
                Text(
                  widget.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      body: _buildListaProdutos(),
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
          return const Center(
            child: Text(
              "Nenhum produto disponível no momento.",
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final produto = docs[i].data() as Map<String, dynamic>;
            return _produtoCard(produto);
          },
        );
      },
    );
  }

  Widget _produtoCard(Map<String, dynamic> produto) {
    // lógica automática de disponibilidade
    bool disponivel = (produto["estoque"] ?? 0) > 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: disponivel ? Colors.grey[200] : Colors.grey[350],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // imagem do produto
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome
                Text(
                  produto["nome"] ?? "Produto sem nome",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Disponibilidade
                Text(
                  disponivel ? "Disponível" : "Indisponível",
                  style: TextStyle(
                    color: disponivel ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                // Descrição adicionada pelo lojista
                Text(
                  produto["descricao"] ?? "Sem descrição",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Preço
          Text(
            "R\$ ${(produto["preco"] ?? 0).toStringAsFixed(2)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
