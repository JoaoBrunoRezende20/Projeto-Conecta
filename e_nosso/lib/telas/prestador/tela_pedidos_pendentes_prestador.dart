import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/menu_lateral.dart';
import '../../utils/usuario_util.dart';

class TelaPedidosPendentesPrestador extends StatefulWidget {
  const TelaPedidosPendentesPrestador({super.key});

  @override
  State<TelaPedidosPendentesPrestador> createState() => _TelaPedidosPendentesPrestadorState();
}

class _TelaPedidosPendentesPrestadorState extends State<TelaPedidosPendentesPrestador> {
  Stream<QuerySnapshot>? _pedidosStream;
  String? _nomeUsuario;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _pedidosStream = FirebaseFirestore.instance
          .collection('pedidos')
          .where('prestadorId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'Pendente')
          .snapshots();
      
      _buscarNomeUsuario(user.uid);
    }
  }

  Future<void> _buscarNomeUsuario(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('prestadorServicos').doc(uid).get();
    if (doc.exists) {
      setState(() {
        _nomeUsuario = UsuarioUtil.getNomeCompleto(doc.data() as Map<String, dynamic>, colecao: 'prestadorServicos');
      });
    }
  }

  void _atualizarStatusPedido(String pedidoId, String novoStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedidoId)
          .update({'status': novoStatus});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(novoStatus == 'Confirmado' 
                ? "Pedido aceito com sucesso!" 
                : "Pedido recusado."),
            backgroundColor: novoStatus == 'Confirmado' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao atualizar pedido: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_circle_left_outlined, color: Colors.black, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      drawer: MenuLateral(
        nomeUsuario: _nomeUsuario ?? "Prestador",
        colecaoUsuario: 'prestadorServicos',
      ),
      body: Column(
        children: [
          const Text(
            "Serviços pendentes",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _pedidosStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Nenhum pedido pendente no momento."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    // Extrai nomes dos serviços da lista
                    final List servicos = data['servicos'] ?? [];
                    final String nomesServicos = servicos.map((s) => s['nome']).join(", ");

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nomesServicos.isNotEmpty ? nomesServicos : "Nome do Serviço",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "R\$ ${(data['valor'] ?? 0).toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.credit_card, size: 18),
                              const SizedBox(width: 8),
                              Text("Pagamento no ${data['pagamento'] ?? 'Crédito'}"),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                "${data['data'] ?? data['dia']} às ${data['horario'] ?? ''}",
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data['endereco'] ?? 'Endereço não informado',
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                data['telefone'] ?? 'Telefone não informado',
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _atualizarStatusPedido(doc.id, 'Rejeitado'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  ),
                                  child: const Text("Rejeitar", style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _atualizarStatusPedido(doc.id, 'Confirmado'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00A36C), // Green
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  ),
                                  child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[600],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                              ),
                              child: const Text("Entrar em contato com o cliente", style: TextStyle(color: Colors.white)),
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
}
