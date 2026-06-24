import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/menu_lateral.dart';
import '../../repositories/pedido_repository.dart';

class TelaPedidosPendentesCliente extends StatefulWidget {
  const TelaPedidosPendentesCliente({super.key});

  @override
  State<TelaPedidosPendentesCliente> createState() => _TelaPedidosPendentesClienteState();
}

class _TelaPedidosPendentesClienteState extends State<TelaPedidosPendentesCliente> {
  final PedidoRepository _pedidoRepository = PedidoRepository();
  final String? clienteId = FirebaseAuth.instance.currentUser?.uid;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _confirmarCancelamento(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Cancelar Pedido"),
        content: const Text("Passaram-se 15 minutos e o lojista não confirmou. Deseja cancelar este pedido?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Voltar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _pedidoRepository.atualizarStatusPedido(id, 'cancelado');
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Pedido cancelado com sucesso.")),
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
            child: const Text("Sim, Cancelar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (clienteId == null) {
      return const Scaffold(body: Center(child: Text("Erro de ID do Cliente")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          "Pedidos Pendentes",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_circle_left_outlined, color: Colors.black, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      drawer: const MenuLateral(
        nomeUsuario: "Cliente",
        colecaoUsuario: 'usuarioComum',
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _pedidoRepository.getPedidosPorCliente(clienteId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Erro: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];
                
                // Filtramos apenas produtos (excluindo serviços) que não foram avaliados ainda
                // e que também não estão finalizados/cancelados.
                final docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final tipo = data['tipo'] ?? 'produto';
                  final avaliado = data['avaliado'] ?? false;
                  final status = (data['status'] ?? 'pendente').toString().toLowerCase();
                  return tipo != 'servico' &&
                      !avaliado &&
                      status != 'concluido' &&
                      status != 'concluído' &&
                      status != 'cancelado' &&
                      status != 'rejeitado';
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Nenhum pedido pendente.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                docs.sort((a, b) {
                  final tA = (a.data() as Map)['dataCriacao'] as Timestamp?;
                  final tB = (b.data() as Map)['dataCriacao'] as Timestamp?;
                  if (tA == null || tB == null) return 0;
                  return tB.compareTo(tA);
                });

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildCardPedido(docs[index].id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPedido(String pedidoId, Map<String, dynamic> data) {
    final loja = data['prestador'] ?? data['loja'] ?? "Loja";
    final valorTotal = (data['valorTotal'] ?? data['valor'] ?? 0.0).toDouble();
    final dataCriacao = data['dataCriacao'] as Timestamp?;
    
    String pagamentoStr = "Crédito";
    final pag = data['pagamento'];
    if (pag != null) {
      if (pag is Map) {
        pagamentoStr = pag['metodo']?.toString() ?? "Crédito";
      } else if (pag is String) {
        pagamentoStr = pag;
      } else if (pag is List && pag.isNotEmpty) {
        final first = pag[0];
        if (first is Map) {
          pagamentoStr = first['metodo']?.toString() ?? "Crédito";
        } else {
          pagamentoStr = first.toString();
        }
      } else {
        pagamentoStr = pag.toString();
      }
    }

    String dataString = data['data'] ?? data['dia'] ?? "Sem data";
    if (dataCriacao != null) {
      final date = dataCriacao.toDate();
      dataString = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
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
      for(var item in data['itens']) {
        itensList.add({
          'nome': item['nome'] ?? 'Produto',
          'quantidade': item['quantidade'] ?? 1,
        });
      }
    }

    if (itensList.isEmpty) {
      itensList.add({'nome': 'Pedido', 'quantidade': 1});
    }

    // Regras de Status
    final statusNorm = (data['status'] ?? 'pendente').toString().toLowerCase();
    final bool isPendente = statusNorm == 'pendente' || statusNorm == 'aguardando';
    final bool isEmAndamento = statusNorm == 'em andamento' || statusNorm == 'em_andamento';
    final bool isConfirmado = statusNorm == 'concluído' || statusNorm == 'concluido' || statusNorm == 'confirmado';
    final bool isRejeitado = statusNorm == 'rejeitado' || statusNorm == 'cancelado';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loja,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                    ),
                    Text(
                      "${item['quantidade']} Unidade${item['quantidade'] > 1 ? 's' : ''}",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            "R\$ ${valorTotal.toStringAsFixed(2).replaceAll('.', ',')}",
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
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
          const SizedBox(height: 20),

          // Lógica de Status Visuais
          if (isPendente) ...[
            const Center(
              child: Text(
                "Aguardando confirmação do pedido",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            if (dataCriacao != null)
              CronometroWidget(
                dataCriacao: dataCriacao,
                onCancelar: () => _confirmarCancelamento(pedidoId),
              ),
          ] else if (isEmAndamento) ...[
            const Center(
              child: Text(
                "Pedido em andamento",
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ] else if (isConfirmado) ...[
            const Center(
              child: Text(
                "Pedido confirmado com sucesso!",
                style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ] else if (isRejeitado) ...[
            const Center(
              child: Text(
                "Pedido Recusado",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CronometroWidget extends StatefulWidget {
  final Timestamp dataCriacao;
  final VoidCallback onCancelar;

  const CronometroWidget({super.key, required this.dataCriacao, required this.onCancelar});

  @override
  State<CronometroWidget> createState() => _CronometroWidgetState();
}

class _CronometroWidgetState extends State<CronometroWidget> {
  Timer? _timer;
  bool passou15Minutos = false;
  String countdownText = "15:00";

  @override
  void initState() {
    super.initState();
    _atualizarTempo();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _atualizarTempo();
    });
  }

  void _atualizarTempo() {
    final diff = DateTime.now().difference(widget.dataCriacao.toDate());
    final secondsPassed = diff.inSeconds;
    final totalSeconds = 15 * 60;
    
    if (secondsPassed >= totalSeconds) {
      if (!passou15Minutos) {
        if (mounted) {
          setState(() {
            passou15Minutos = true;
          });
        }
      }
      _timer?.cancel();
    } else {
      final secondsRemaining = totalSeconds - secondsPassed;
      final m = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
      final s = (secondsRemaining % 60).toString().padLeft(2, '0');
      if (mounted) {
        setState(() {
          countdownText = "$m:$s";
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (passou15Minutos) {
      return Column(
        children: [
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onCancelar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Cancelar pedido", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        const SizedBox(height: 5),
        Center(
          child: Text(
            countdownText,
            style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ],
    );
  }
}

