import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tela_avaliacao_servico.dart';
import '../../repositories/pedido_repository.dart';

class TelaHistoricoPedidos extends StatefulWidget {
  const TelaHistoricoPedidos({super.key});

  @override
  State<TelaHistoricoPedidos> createState() => _TelaHistoricoPedidosState();
}

class _TelaHistoricoPedidosState extends State<TelaHistoricoPedidos> {
  final PedidoRepository _pedidoRepository = PedidoRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.menu, color: Colors.black),
        title: const Text(
          "Histórico",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 18,
                ),
                padding: const EdgeInsets.only(left: 6),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Text(
            "HISTÓRICO DE COMPRAS E SERVIÇOS",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _pedidoRepository.getPedidosPorCliente(
                FirebaseAuth.instance.currentUser?.uid ?? '',
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Erro ao carregar: ${snapshot.error}"),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];
                if (allDocs.isEmpty) {
                  return const Center(child: Text("Nenhum pedido encontrado."));
                }

                // Filtrar apenas finalizados: concluído
                final docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '')
                      .toString()
                      .toLowerCase();
                  return status == 'concluído' || status == 'concluido';
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text("Nenhum serviço no histórico."),
                  );
                }

                final sortedDocs = List.from(docs);
                sortedDocs.sort((a, b) {
                  final tA = (a.data() as Map)['dataCriacao'] as Timestamp?;
                  final tB = (b.data() as Map)['dataCriacao'] as Timestamp?;
                  if (tA == null || tB == null) return 0;
                  return tB.compareTo(tA); // Descendente
                });

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: sortedDocs.length,
                  itemBuilder: (context, index) {
                    final data =
                        sortedDocs[index].data() as Map<String, dynamic>;
                    final id = sortedDocs[index].id;
                    return _buildCard(id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String id, Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().toLowerCase();
    final bool concluido = status == 'concluído' || status == 'concluido';
    final bool cancelado = status == 'cancelado';

    final loja = data['nomeLoja'] ?? data['loja'] ?? data['prestador'] ?? "Loja";
    final valorTotal = (data['valorTotal'] ?? data['valor'] ?? 0.0).toDouble();

    String pagamentoStr = "Crédito";
    if (data['pagamento'] != null && data['pagamento']['metodo'] != null) {
      pagamentoStr = data['pagamento']['metodo'];
    } else if (data['pagamento'] is String) {
      pagamentoStr = data['pagamento'];
    }

    String dataString = data['data'] ?? data['dia'] ?? "Sem data";
    final dataCriacao = data['dataCriacao'] as Timestamp?;
    if (dataCriacao != null) {
      final date = dataCriacao.toDate();
      dataString =
          "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }

    List<Map<String, dynamic>> itensList = [];
    if (data['itens'] is Map) {
      (data['itens'] as Map).forEach((key, val) {
        itensList.add({
          'nome': val['nome'] ?? 'Produto',
          'quantidade': val['quantidade'] ?? 1,
        });
      });
    } else if (data['itens'] is List) {
      for (var item in data['itens']) {
        itensList.add({
          'nome': item['nome'] ?? 'Produto',
          'quantidade': item['quantidade'] ?? 1,
        });
      }
    }

    final bool avaliado = data['avaliado'] ?? false;
    final prestadorId = data['lojistaId'] ?? data['prestadorId'] ?? "";

    Color statusColor =
        concluido ? Colors.green : (cancelado ? Colors.red : Colors.grey);
    String statusLabel = concluido
        ? "Pedido Concluído"
        : (cancelado ? "Cancelado" : "Finalizado");

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200], // Fundo cinza claro conforme imagem
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  loja,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          Column(
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "${item['quantidade']} Unidade${item['quantidade'] > 1 ? 's' : ''}",
                      style:
                          const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            "R\$ ${valorTotal.toStringAsFixed(2).replaceAll('.', ',')}",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.credit_card, size: 18),
              const SizedBox(width: 8),
              Text("Pagamento no $pagamentoStr"),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                dataString,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
          if (concluido && !avaliado) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TelaAvaliacaoServico(
                        pedidoId: id,
                        prestadorId: prestadorId,
                        nomePrestador: loja,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF8B9467,
                  ), // Cor verde oliva da imagem
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "AVALIAR LOJA",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmarCancelamento(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Confirmar Cancelamento"),
        content: const Text("Tem certeza que deseja cancelar este pedido?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Voltar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _pedidoRepository.atualizarStatusPedido(id, 'Cancelado');

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Solicitação cancelada com sucesso."),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erro ao cancelar: $e")),
                  );
                }
              }
            },
            child: const Text(
              "Sim, Cancelar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
