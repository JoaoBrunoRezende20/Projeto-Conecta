import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../repositories/pedido_repository.dart';
import '../../../repositories/produto_repository.dart';

class AbaPedidosLojista extends StatefulWidget {
  final String lojistaId;

  const AbaPedidosLojista({super.key, required this.lojistaId});

  @override
  State<AbaPedidosLojista> createState() => _AbaPedidosLojistaState();
}

class _AbaPedidosLojistaState extends State<AbaPedidosLojista> {
  final PedidoRepository _pedidoRepository = PedidoRepository();
  final ProdutoRepository _produtoRepository = ProdutoRepository();
  String? _nomeLoja;

  @override
  void initState() {
    super.initState();
    _carregarNomeLoja();
  }

  Future<void> _carregarNomeLoja() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('lojistas')
          .doc(widget.lojistaId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _nomeLoja = data['razaoSocial'] ?? data['nomeFantasia'] ?? 'Loja';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _atualizarStatusPedido(
    String pedidoId,
    String novoStatus,
    Map<String, dynamic> itens, {
    String? clienteId,
  }) async {
    await _pedidoRepository.atualizarStatusPedido(pedidoId, novoStatus);

    // Envia notificação em tempo real para o cliente
    if (clienteId != null && clienteId.isNotEmpty) {
      final nomeExibicaoLoja = _nomeLoja ?? "a loja";
      if (novoStatus == 'em andamento') {
        await _pedidoRepository.enviarNotificacao(
          destinatarioId: clienteId,
          colecaoDestinatario: 'usuarioComum',
          titulo: 'Pedido Aceito!',
          mensagem: 'Seu pedido na loja $nomeExibicaoLoja foi confirmado e está em preparação.',
          tipo: 'pedido_aceito',
          pedidoId: pedidoId,
        );
      } else if (novoStatus == 'concluido') {
        await _pedidoRepository.enviarNotificacao(
          destinatarioId: clienteId,
          colecaoDestinatario: 'usuarioComum',
          titulo: 'Pedido Concluído!',
          mensagem: 'Seu pedido na loja $nomeExibicaoLoja foi finalizado. Não se esqueça de avaliar a sua experiência!',
          tipo: 'pedido_concluido',
          pedidoId: pedidoId,
        );
      } else if (novoStatus == 'cancelado' || novoStatus == 'rejeitado') {
        await _pedidoRepository.enviarNotificacao(
          destinatarioId: clienteId,
          colecaoDestinatario: 'usuarioComum',
          titulo: 'Pedido Recusado',
          mensagem: 'Infelizmente seu pedido na loja $nomeExibicaoLoja não pôde ser atendido.',
          tipo: 'pedido_recusado',
          pedidoId: pedidoId,
        );
      }
    }

    // Devolve estoque quando lojista cancela ou recusa o pedido
    if (novoStatus == 'cancelado' || novoStatus == 'rejeitado') {
      for (final entry in itens.entries) {
        final produtoId = entry.key;
        final itemData = entry.value as Map<String, dynamic>;
        final quantidade = (itemData['quantidade'] as num).toInt();
        await _produtoRepository.devolverEstoqueProduto(produtoId, quantidade);
      }
    }
  }

  String _formatarData(Timestamp? timestamp) {
    if (timestamp == null) return "00/00/0000";
    final data = timestamp.toDate();
    return "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}";
  }

  Widget _buildCardPedido(Map<String, dynamic> pedido, String pedidoId) {
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
    if (pedido['dadosEntrega'] != null &&
        pedido['dadosEntrega']['tipoEntrega'] != null) {
      final tipo = pedido['dadosEntrega']['tipoEntrega'];
      final endereco = pedido['dadosEntrega']['endereco'];
      if (tipo == 'Entrega' &&
          endereco != null &&
          endereco.toString().isNotEmpty) {
        entregaStr = "Entrega: $endereco";
      } else {
        entregaStr = tipo;
      }
    }

    // Extrair Itens
    List<Map<String, dynamic>> itensList = [];
    if (pedido['itens'] is Map) {
      (pedido['itens'] as Map).forEach((key, val) {
        itensList.add({
          'nome': val['nome'] ?? 'Produto',
          'quantidade': val['quantidade'] ?? 1,
        });
      });
    } else if (pedido['itens'] is List) {
      for (var item in (pedido['itens'] as List)) {
        itensList.add({
          'nome': item['nome'] ?? 'Serviço',
          'quantidade': item['quantidade'] ?? 1,
        });
      }
    }

    if (itensList.isEmpty) {
      itensList.add({'nome': 'Pedido', 'quantidade': 1});
    }

    final nomeCliente = dadosCliente['nome'] ?? 'Cliente';

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5), // Fundo cinza claro
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinhado à esquerda
        children: [
          Text(
            "$nomeCliente**",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coluna da Esquerda (Itens)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: itensList.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(width: 15),

              // Coluna da Direita (Valores e Infos)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "R\$ ${valorTotal.toStringAsFixed(2).replaceAll('.', ',')}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Pagamento no $pagamentoStr",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entregaStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatarData(dataCriacao),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          if (status == 'pendente') ...[
            const Center(
              child: Text(
                "Produto disponível no estoque!",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _atualizarStatusPedido(
                  pedidoId,
                  'em andamento',
                  pedido['itens'] is Map
                      ? Map<String, dynamic>.from(pedido['itens'] as Map)
                      : {},
                  clienteId: pedido['clienteId'],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text(
                  "Confirmar Pedido",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _atualizarStatusPedido(
                  pedidoId,
                  'cancelado',
                  pedido['itens'] is Map
                      ? Map<String, dynamic>.from(pedido['itens'] as Map)
                      : {},
                  clienteId: pedido['clienteId'],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text(
                  "Recusar Pedido",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (status == 'em andamento') ...[
            const Center(
              child: Text(
                "Pedido em preparação",
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _atualizarStatusPedido(
                  pedidoId,
                  'concluido',
                  pedido['itens'] is Map
                      ? Map<String, dynamic>.from(pedido['itens'] as Map)
                      : {},
                  clienteId: pedido['clienteId'],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text(
                  "Concluir Pedido",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // BOTÃO CHAT
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E8E8E), // Cinza botão
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: const Text(
                "Entrar em chat com cliente",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _pedidoRepository.getPedidosPorLojista(widget.lojistaId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Erro: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
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
          return status != 'concluido' &&
              status != 'cancelado' &&
              status != 'rejeitado';
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
          // ignore error
        }

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "Você ainda não recebeu nenhum pedido.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            return _buildCardPedido(doc.data() as Map<String, dynamic>, doc.id);
          },
        );
      },
    );
  }
}
