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

class _TelaProdutosDisponiveisState extends State<TelaProdutosDisponiveis>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
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
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
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
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),

      body: Column(
        children: [
          Container(
            color: Colors.grey[200],
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              tabs: const [
                Tab(text: "Salgados"),
                Tab(text: "Bebidas"),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _streamProdutos("Salgado"),
                _streamProdutos("Bebida"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _streamProdutos(String categoria) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('produtos')
          .where('idLoja', isEqualTo: widget.lojaId)
          .where('categoria', isEqualTo: categoria)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("Nenhum produto disponível."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final item = docs[i].data() as Map<String, dynamic>;

            return _produtoCard(item);
          },
        );
      },
    );
  }

  Widget _produtoCard(Map<String, dynamic> produto) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[350],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produto["nome"] ?? "Produto sem nome",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  produto["descricao"] ?? "Descrição do produto",
                  style: TextStyle(color: Colors.grey[700]),
                ),

                Row(
                  children: [
                    const Icon(Icons.star_border, size: 16),
                    Text((produto["nota"] ?? 5.0).toString()),
                  ],
                ),
              ],
            ),
          ),

          Text(
            "R\$${(produto["preco"] ?? 0).toStringAsFixed(2)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
