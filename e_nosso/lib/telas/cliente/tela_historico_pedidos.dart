import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelaHistoricoPedidos extends StatefulWidget {
  const TelaHistoricoPedidos({super.key});

  @override
  State<TelaHistoricoPedidos> createState() => _TelaHistoricoPedidosState();
}

class _TelaHistoricoPedidosState extends State<TelaHistoricoPedidos> {
  // Lista unificada: o campo 'tipo' define se é Produto ou Serviço
  List<Map<String, dynamic>> historicoGeral = [
    {
      "id": "101",
      "tipo": "produto", // Exemplo de Produto
      "loja": "Emporio da bebida",
      "data": "05/05/2026",
      "pagamento": "Crédito",
      "entrega": "Entrega em casa",
      "status": "Pedido confirmed!",
      "ehPendente": false,
      "total": 37.00,
      "itens": [
        {"nome": "Cerveja brahma", "quantidade": 5},
        {"nome": "Agua mineral", "quantidade": 1},
      ],
    },
    {
      "id": "201",
      "tipo": "servico", // Exemplo de Serviço
      "loja": "Eletricista Fulano de tal",
      "data": "05/07/2026",
      "pagamento": "Crédito",
      "entrega": "Agendado",
      "status": "Aguardando confirmação!",
      "ehPendente": true,
      "total": 100.00,
      "itens": [
        {"nome": "Instalação de Chuveiro", "quantidade": 1},
      ],
    },
  ];

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
              stream: FirebaseFirestore.instance
                  .collection('pedidos')
                  .where(
                    'clienteId',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                  )
                  .orderBy('dataCriacao', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Erro ao carregar: ${snapshot.error}"),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text("Nenhum pedido encontrado."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final id = docs[index].id;

                    // Adaptando dados do Firestore para a estrutura do Card
                    final itemAdaptado = {
                      "id": id,
                      "tipo": data['tipo'] ?? 'produto',
                      "loja": data['prestador'] ?? data['loja'] ?? "Loja",
                      "data": data['tipo'] == 'servico'
                          ? "${data['data'] ?? data['dia']} às ${data['horario'] ?? ''}"
                          : data['data'] ?? data['dia'] ?? "Sem data",
                      "pagamento": data['pagamento'] ?? "Cartão/Pix",
                      "entrega":
                          data['entrega'] ??
                          (data['tipo'] == 'servico' ? "Agendado" : "Entrega"),
                      "status": data['status'] ?? "Pendente",
                      "ehPendente":
                          data['status'] == "Pendente" ||
                          data['status'] == "Aguardando confirmação!",
                      "total": (data['valor'] ?? 0).toDouble(),
                      "itens": data['servicos'] ?? data['itens'] ?? [],
                    };

                    return _buildCard(itemAdaptado);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    bool ehServico = item['tipo'] == 'servico';
    bool pendente = item['ehPendente'];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[300], // Fundo cinza conforme mockups
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho: Nome e Valores
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item['loja'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "R\$ ${item['total'].toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Pago no ${item['pagamento']}",
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(item['entrega'], style: const TextStyle(fontSize: 11)),
                  Text(item['data'], style: const TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Listagem de Itens
          ...item['itens']
              .map<Widget>(
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i['nome'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (!ehServico) // Só mostra "Unidades" para produtos
                        Text(
                          "${i['quantidade']} Unidades",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
              )
              .toList(),

          const SizedBox(height: 20),

          // Status Centralizado
          Center(
            child: Text(
              item['status'],
              style: TextStyle(
                color: pendente ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Botão de Chat Adaptável
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                ehServico
                    ? "Entrar em contato com o prestador"
                    : "Entrar em chat com o vendedor",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),

          // Botão de Cancelamento (Critério de Aceite)
          if (pendente) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _confirmarCancelamento(item['id']),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "CANCELAR SOLICITAÇÃO",
                  style: TextStyle(
                    color: Colors.red,
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
      builder: (context) => AlertDialog(
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
                await FirebaseFirestore.instance
                    .collection('pedidos')
                    .doc(id)
                    .update({'status': 'Cancelado'});

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Solicitação cancelada com sucesso."),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Erro ao cancelar: $e")));
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
