import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/menu_lateral.dart';
import '../../utils/usuario_util.dart';
import '../../repositories/pedido_repository.dart';
import '../../repositories/usuario_repository.dart';

class TelaServicosAgendadosPrestador extends StatefulWidget {
  const TelaServicosAgendadosPrestador({super.key});

  @override
  State<TelaServicosAgendadosPrestador> createState() => _TelaServicosAgendadosPrestadorState();
}

class _TelaServicosAgendadosPrestadorState extends State<TelaServicosAgendadosPrestador> {
  Stream<QuerySnapshot>? _pedidosStream;
  String? _nomeUsuario;
  final PedidoRepository _pedidoRepository = PedidoRepository();
  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _pedidosStream = _pedidoRepository.getPedidosPorPrestador(user.uid, 'Confirmado');
      
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

  void _concluirServico(String pedidoId, {String? clienteId}) async {
    try {
      await _pedidoRepository.atualizarStatusPedido(pedidoId, 'Concluído');

      // Notifica o cliente em tempo real
      if (clienteId != null && clienteId.isNotEmpty) {
        final nomePrestador = _nomeUsuario ?? "O prestador";
        await _pedidoRepository.enviarNotificacao(
          destinatarioId: clienteId,
          colecaoDestinatario: 'usuarioComum',
          titulo: 'Serviço Concluído!',
          mensagem: '$nomePrestador finalizou seu atendimento. Não esqueça de avaliar o serviço!',
          tipo: 'servico_concluido',
          pedidoId: pedidoId,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Serviço concluído com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao concluir serviço: $e"), backgroundColor: Colors.red),
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
            "Serviços agendados",
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
                  return const Center(child: Text("Nenhum serviço agendado no momento."));
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
                                  onPressed: () => _concluirServico(
                                    doc.id,
                                    clienteId: data['clienteId'],
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00A36C), // Green
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  ),
                                  child: const Text("Concluir Serviço", style: TextStyle(color: Colors.white)),
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
