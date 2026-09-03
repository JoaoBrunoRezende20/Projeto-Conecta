import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/menu_lateral.dart';
import '../../utils/usuario_util.dart';
import '../../repositories/pedido_repository.dart';
import '../../repositories/usuario_repository.dart';

class TelaHistoricoServicosPrestador extends StatefulWidget {
  const TelaHistoricoServicosPrestador({super.key});

  @override
  State<TelaHistoricoServicosPrestador> createState() => _TelaHistoricoServicosPrestadorState();
}

class _TelaHistoricoServicosPrestadorState extends State<TelaHistoricoServicosPrestador> {
  Stream<QuerySnapshot>? _pedidosStream;
  String? _nomeUsuario;
  final PedidoRepository _pedidoRepository = PedidoRepository();
  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _pedidosStream = _pedidoRepository.getPedidosPorPrestador(user.uid, 'Concluído');
      
      _buscarNomeUsuario(user.uid);
    }
  }

  Future<void> _buscarNomeUsuario(String uid) async {
    final doc = await _usuarioRepository.getUsuario(uid, 'prestadorServicos');
    if (doc.exists) {
      setState(() {
        _nomeUsuario = UsuarioUtil.getNomeCompleto(doc.data() as Map<String, dynamic>, colecao: 'prestadorServicos');
      });
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
          Builder(
            builder: (context) {
              final canPop = ModalRoute.of(context)?.canPop ?? false;
              if (!canPop) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.arrow_circle_left_outlined, color: Colors.black, size: 30),
                onPressed: () => Navigator.pop(context),
              );
            },
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
            "Histórico de serviços",
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
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text("Nenhum serviço concluído no momento."));
                }

                // Ordenação manual client-side para evitar erro de índice no Firestore
                final sortedDocs = List.from(docs);
                sortedDocs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final Timestamp? tA = dataA['dataCriacao'] as Timestamp?;
                  final Timestamp? tB = dataB['dataCriacao'] as Timestamp?;
                  if (tA == null || tB == null) return 0;
                  return tB.compareTo(tA); // Descendente
                });

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: sortedDocs.length,
                  itemBuilder: (context, index) {
                    final doc = sortedDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
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
                          const Center(
                            child: Text(
                              "Serviço concluído!",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
}
