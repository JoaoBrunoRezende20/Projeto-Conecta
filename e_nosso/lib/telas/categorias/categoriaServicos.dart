import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoriaServicos extends StatefulWidget {
  const CategoriaServicos({super.key});

  @override
  State<CategoriaServicos> createState() => _CategoriaServicosState();
}

class _CategoriaServicosState extends State<CategoriaServicos> {
  String pesquisa = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Serviços",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          // Barra de busca
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                onChanged: (value) => setState(() => pesquisa = value.trim()),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: "Pesquisar prestador...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // Lista de prestadores
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('prestadorServicos')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Nenhum prestador cadastrado."),
                  );
                }

                // Filtro por nome
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nome =
                  ("${data['nome'] ?? ''} ${data['sobrenome'] ?? ''}")
                      .toLowerCase();

                  return nome.contains(pesquisa.toLowerCase());
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("Nenhum prestador encontrado."));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    final nomeCompleto =
                        "${data['nome'] ?? ''} ${data['sobrenome'] ?? ''}";

                    // 🔥 CORREÇÃO IMPORTANTE:
                    // No cadastro, o campo é salvo como "areaAtuacao" (sem acento)
                    final area =
                    (data['areaAtuacao'] ?? 'Serviços').toString();

                    final preco =
                    (data['faixaPrecos'] ?? 'Sob consulta').toString();

                    return _buildServicoCard(
                      nome: nomeCompleto,
                      areaAtuacao: area,
                      preco: preco,
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

  Widget _buildServicoCard({
    required String nome,
    required String areaAtuacao,
    required String preco,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEEE),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Foto / ícone do prestador
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(width: 12),

          // Informações
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text("⭐ 5.0  •  $areaAtuacao"),
                Text("A partir de R\$ $preco"),
              ],
            ),
          ),

          const Icon(Icons.star_border),
        ],
      ),
    );
  }
}
