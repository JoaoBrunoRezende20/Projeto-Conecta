import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class TelaConfirmacaoServico extends StatefulWidget {
  const TelaConfirmacaoServico({super.key});

  @override
  State<TelaConfirmacaoServico> createState() => _TelaConfirmacaoServicoState();
}

class _TelaConfirmacaoServicoState extends State<TelaConfirmacaoServico> {
  late Timer _timer;
  Stream<QuerySnapshot>? _pedidosStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Busca TODOS os pedidos do cliente — filtramos client-side
      _pedidosStream = FirebaseFirestore.instance
          .collection('pedidos')
          .where('clienteId', isEqualTo: user.uid)
          .snapshots();
    }
    // Atualiza o cronômetro a cada segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Pedido finalizado = some da tela de pendentes e vai para o histórico
  bool _isFinalizado(String status) {
    final s = status.toLowerCase();
    return s == 'concluido' ||
        s == 'concluído' ||
        s == 'cancelado' ||
        s == 'rejeitado';
  }

  // Confirmado = lojista aceitou ('aceito') ou prestador confirmou ('Confirmado')
  bool _isConfirmado(String status) {
    final s = status.toLowerCase();
    return s == 'aceito' || s == 'confirmado';
  }

  // Pendente = ainda não teve resposta do lojista/prestador
  bool _isPendente(String status) {
    return status.toLowerCase() == 'pendente';
  }

  // Pode cancelar: apenas se pendente E após 15 minutos sem confirmação
  bool _podeCancelar(Timestamp? dataCriacao, String status) {
    if (!_isPendente(status)) return false;
    if (dataCriacao == null) return true; // sem data: libera por segurança
    final diferenca = DateTime.now().difference(dataCriacao.toDate());
    return diferenca.inMinutes >= 15;
  }

  String _tempoRestanteMMSS(Timestamp dataCriacao) {
    final diff = DateTime.now().difference(dataCriacao.toDate());
    final restanteSegundos = (15 * 60) - diff.inSeconds;
    if (restanteSegundos <= 0) return "00:00";
    final minutos = (restanteSegundos ~/ 60).toString().padLeft(2, '0');
    final segundos = (restanteSegundos % 60).toString().padLeft(2, '0');
    return "$minutos:$segundos";
  }

  String _getNomePedido(Map<String, dynamic> data) {
    final bool ehServico = data['tipo'] == 'servico';
    if (ehServico) {
      if (data['prestador'] != null) return data['prestador'];
      final List servicos = data['servicos'] ?? [];
      if (servicos.isNotEmpty) {
        return servicos.map((s) => s['nome'] ?? '').join(', ');
      }
      return 'Serviço';
    } else {
      // Produtos: pega o nome do primeiro item do mapa
      if (data['itens'] is Map) {
        final itens = data['itens'] as Map;
        if (itens.isNotEmpty) {
          final primeiro = itens.values.first;
          if (primeiro is Map) return primeiro['nome']?.toString() ?? 'Pedido';
        }
      }
      if (data['itens'] is List) {
        final itens = data['itens'] as List;
        if (itens.isNotEmpty) return itens.first['nome']?.toString() ?? 'Pedido';
      }
      return 'Pedido';
    }
  }

  double _getValor(Map<String, dynamic> data) {
    return (data['valorTotal'] ?? data['valor'] ?? 0.0).toDouble();
  }

  String _getPagamento(Map<String, dynamic> data) {
    if (data['pagamento'] is Map) {
      return (data['pagamento'] as Map)['metodo']?.toString() ?? 'Cartão';
    }
    return data['pagamento']?.toString() ?? 'Cartão';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.arrow_circle_left_outlined,
              color: Colors.black,
              size: 30,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            "Pedidos Pendentes",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _pedidosStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text("Nenhum pedido pendente."));
                }

                // Filtra client-side: remove os finalizados
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '').toString();
                  return !_isFinalizado(status);
                }).toList();

                // Ordena: mais recente primeiro
                try {
                  docs.sort((a, b) {
                    final tA = (a.data() as Map<String, dynamic>)['dataCriacao'] as Timestamp?;
                    final tB = (b.data() as Map<String, dynamic>)['dataCriacao'] as Timestamp?;
                    if (tA == null && tB == null) return 0;
                    if (tA == null) return 1;
                    if (tB == null) return -1;
                    return tB.compareTo(tA);
                  });
                } catch (_) {}

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Nenhum pedido pendente.",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final dataCriacao = data['dataCriacao'] as Timestamp?;
                    final String status = (data['status'] ?? 'Pendente').toString();
                    final bool isConfirmado = _isConfirmado(status);
                    final bool isPendente = _isPendente(status);
                    final bool podeCancelar = _podeCancelar(dataCriacao, status);
                    final bool ehServico = data['tipo'] == 'servico';

                    final nomePedido = _getNomePedido(data);
                    final valor = _getValor(data);
                    final pagamento = _getPagamento(data);

                    // Subtítulo: data/horário para serviços ou tipo entrega para produtos
                    String subtitulo = '';
                    if (ehServico) {
                      final dia = (data['data'] ?? data['dia'] ?? '').toString();
                      final horario = (data['horario'] ?? '').toString();
                      if (dia.isNotEmpty) subtitulo = "$dia às $horario";
                    } else {
                      final dadosEntrega = data['dadosEntrega'];
                      if (dadosEntrega is Map) {
                        final tipo = dadosEntrega['tipoEntrega']?.toString() ?? '';
                        final endereco = dadosEntrega['endereco']?.toString() ?? '';
                        subtitulo = (tipo == 'Entrega' && endereco.isNotEmpty)
                            ? "Entrega: $endereco"
                            : tipo;
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 25),
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nomePedido,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}",
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.credit_card,
                                size: 18,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Pagamento no $pagamento",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          if (subtitulo.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              subtitulo,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // STATUS: verde se confirmado, vermelho se aguardando
                          Center(
                            child: Text(
                              isConfirmado
                                  ? "Pedido confirmado! ✓"
                                  : "Aguardando confirmação...",
                              style: TextStyle(
                                color: isConfirmado ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Botão de contato
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[500],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                              ),
                              child: Text(
                                ehServico
                                    ? "Entrar em contato com o prestador"
                                    : "Entrar em contato com a loja",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ),

                          // Botão cancelar — só aparece enquanto pendente (sem confirmação)
                          if (isPendente) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: podeCancelar
                                    ? () => _cancelarPedido(doc.id)
                                    : null,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: podeCancelar
                                        ? Colors.red
                                        : Colors.grey.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                                child: Text(
                                  "Cancelar Pedido",
                                  style: TextStyle(
                                    color: podeCancelar
                                        ? Colors.red
                                        : Colors.grey.withOpacity(0.5),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            // Cronômetro de cancelamento
                            if (!podeCancelar && dataCriacao != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Center(
                                  child: Text(
                                    "Cancelamento disponível em: ${_tempoRestanteMMSS(dataCriacao)}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _cancelarPedido(String id) async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar"),
        content: const Text("Deseja realmente cancelar este pedido?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Não"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sim"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(id)
          .update({'status': 'Cancelado'});
    }
  }
}
