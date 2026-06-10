import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelaHistoricoPedidosLojista extends StatefulWidget {
  const TelaHistoricoPedidosLojista({super.key});

  @override
  State<TelaHistoricoPedidosLojista> createState() => _TelaHistoricoPedidosLojistaState();
}

class _TelaHistoricoPedidosLojistaState extends State<TelaHistoricoPedidosLojista> {
  final String? lojistaId = FirebaseAuth.instance.currentUser?.uid;

  String _formatarData(Timestamp? timestamp) {
    if (timestamp == null) return "00/00/0000";
    final data = timestamp.toDate();
    return "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}";
  }

  @override
  Widget build(BuildContext context) {
    if (lojistaId == null) {
      return const Scaffold(
        body: Center(child: Text("Erro de ID do Lojista")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Histórico de Pedidos',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pedidos')
            .where('lojistaId', isEqualTo: lojistaId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Erro: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data!.docs.toList();
          final docs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status']?.toString().toLowerCase() ?? 'pendente';
            return status == 'concluído' || status == 'concluido';
          }).toList();

          try {
            docs.sort((a, b) {
              final mapA = a.data() as Map<String, dynamic>?;
              final mapB = b.data() as Map<String, dynamic>?;

              final dataA = mapA?['dataCriacao'];
              final dataB = mapB?['dataCriacao'];

              final Timestamp? tA = dataA is Timestamp ? dataA : null;
              final Timestamp? tB = dataB is Timestamp ? dataB : null;

              if (tA == null && tB == null) return 0;
              if (tA == null) return 1;
              if (tB == null) return -1;

              return tB.compareTo(tA);
            });
          } catch (e) {
            debugPrint("Erro ao ordenar histórico: $e");
          }

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Nenhum pedido finalizado no histórico.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              return _buildCardHistorico(doc.data() as Map<String, dynamic>);
            },
          );
        },
      ),
    );
  }

  Widget _buildCardHistorico(Map<String, dynamic> pedido) {
    final dadosCliente = pedido['dadosCliente'] ?? {};
    final status = pedido['status']?.toString().toLowerCase() ?? 'pendente';
    final valorTotal = (pedido['valorTotal'] ?? 0.0).toDouble();
    final dataCriacao = pedido['dataCriacao'] as Timestamp?;

    String pagamentoStr = "Crédito";
    if (pedido['pagamento'] != null && pedido['pagamento']['metodo'] != null) {
      pagamentoStr = pedido['pagamento']['metodo'];
    } else if (pedido['pagamento'] is String) {
      pagamentoStr = pedido['pagamento'];
    }

    String entregaStr = "Entrega em casa";
    if (pedido['dadosEntrega'] != null && pedido['dadosEntrega']['tipoEntrega'] != null) {
      final tipo = pedido['dadosEntrega']['tipoEntrega'];
      final endereco = pedido['dadosEntrega']['endereco'];
      if (tipo == 'Entrega' && endereco != null && endereco.toString().isNotEmpty) {
        entregaStr = "Entrega: $endereco";
      } else {
        entregaStr = tipo;
      }
    }

    List<Map<String, dynamic>> itensList = [];
    if (pedido['itens'] is Map) {
      (pedido['itens'] as Map).forEach((key, val) {
        itensList.add({
          'nome': val['nome'] ?? 'Produto',
          'quantidade': val['quantidade'] ?? 1,
        });
      });
    }

    if (itensList.isEmpty) {
      itensList.add({'nome': 'Pedido', 'quantidade': 1});
    }

    final nomeCliente = dadosCliente['nome'] ?? 'Cliente';

    Color statusColor = Colors.green;
    String statusLabel = "Entregue";
    if (status == 'cancelado' || status == 'rejeitado') {
      statusColor = Colors.red;
      statusLabel = "Recusado / Cancelado";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$nomeCliente**",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: itensList.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['nome'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            "${item['quantidade']} Unidade${item['quantidade'] > 1 ? 's' : ''}",
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "R\$ ${valorTotal.toStringAsFixed(2).replaceAll('.', ',')}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Pagamento no $pagamentoStr",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entregaStr,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatarData(dataCriacao),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
