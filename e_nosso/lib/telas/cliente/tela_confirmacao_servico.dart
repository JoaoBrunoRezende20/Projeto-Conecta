import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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
      _pedidosStream = FirebaseFirestore.instance
          .collection('pedidos')
          .where('clienteId', isEqualTo: user.uid)
          .where('status', whereIn: ['Pendente', 'Confirmado'])
          .where('tipo', isEqualTo: 'servico')
          .snapshots();
    }

    // Timer para atualizar a tela a cada segundo (cronômetro)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  bool _podeCancelar(Timestamp? dataCriacao, String status) {
    if (status == 'Confirmado') return false; // Não pode cancelar se já confirmado
    if (dataCriacao == null) return true; // Se não tem data (pedidos antigos), permite cancelar por segurança
    
    final diferenca = DateTime.now().difference(dataCriacao.toDate());
    return diferenca.inMinutes >= 15;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
            icon: const Icon(Icons.arrow_circle_left_outlined,
                color: Colors.black, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            "Serviços pendentes",
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
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Nenhum serviço pendente."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final dataCriacao = data['dataCriacao'] as Timestamp?;
                    final String status = data['status'] ?? 'Pendente';
                    final podeCancelar = _podeCancelar(dataCriacao, status);
                    final bool isConfirmado = status == 'Confirmado';

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
                            data['prestador'] ?? "Nome do Serviço",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "R\$ ${(data['valor'] ?? 0).toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.credit_card,
                                  size: 18, color: Colors.black54),
                              const SizedBox(width: 8),
                              Text(
                                "Pagamento no ${data['pagamento'] ?? 'Crédito'}",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "${data['data'] ?? data['dia']} às ${data['horario'] ?? ''}",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Text(
                              status == 'Confirmado'
                                  ? "Serviço confirmado"
                                  : (status == 'Rejeitado'
                                      ? "Serviço recusado"
                                      : "Aguardando confirmação!"),
                              style: TextStyle(
                                color: status == 'Confirmado'
                                    ? Colors.green
                                    : (status == 'Rejeitado'
                                        ? Colors.orange
                                        : Colors.red),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[500],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                "Entrar em contato com o prestador",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Botão de Cancelamento condicional
                          if (!isConfirmado)
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
                          if (!isConfirmado && !podeCancelar && dataCriacao != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Center(
                                child: Text(
                                  "Cancelamento disponível em: ${_tempoRestanteMMSS(dataCriacao)}",
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
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

  String _tempoRestanteMMSS(Timestamp dataCriacao) {
    final diff = DateTime.now().difference(dataCriacao.toDate());
    final restanteSegundos = (15 * 60) - diff.inSeconds;

    if (restanteSegundos <= 0) return "00:00";

    final minutos = (restanteSegundos ~/ 60).toString().padLeft(2, '0');
    final segundos = (restanteSegundos % 60).toString().padLeft(2, '0');

    return "$minutos:$segundos";
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
              child: const Text("Não")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Sim")),
        ],
      ),
    );

    if (confirmar == true) {
      await FirebaseFirestore.instance.collection('pedidos').doc(id).update({
        'status': 'Cancelado',
      });
    }
  }
}
