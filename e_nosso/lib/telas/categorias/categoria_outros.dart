import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../cliente/tela_produtos_disponiveis.dart';

class CategoriaOutros extends StatefulWidget {
  const CategoriaOutros({super.key});

  @override
  State<CategoriaOutros> createState() => _CategoriaOutrosState();
}

class _CategoriaOutrosState extends State<CategoriaOutros> {
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
        title: const Text("Outros", style: TextStyle(color: Colors.black)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                onChanged: (v) => setState(() => pesquisa = v.trim()),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: "Pesquisar loja...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("lojistas")
                  .where("cnae", isEqualTo: "Outros")
                  .where('statusCadastro', isEqualTo: 'aprovado')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nome =
                      (data["razaoSocial"] ?? data["nomeLojista"] ?? "")
                          .toString()
                          .toLowerCase();
                  return nome.contains(pesquisa.toLowerCase());
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text("Nenhum estabelecimento encontrado."),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final nome = (data["razaoSocial"] ?? data["nomeLojista"])
                        .toString();
                    final descricao = (data["descricao"] ?? "Sem descrição")
                        .toString();

                    return _buildLojaCard(
                      context: context,
                      lojaId: docs[index].id,
                      nome: nome,
                      categoriaTexto: "Outros",
                      descricaoExtra: descricao,
                      avaliacao: 5.0,
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

  Widget _buildLojaCard({
    required BuildContext context,
    required String lojaId,
    required String nome,
    required String categoriaTexto,
    required String descricaoExtra,
    required double avaliacao,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TelaProdutosDisponiveis(
              lojaId: lojaId,
              storeName: nome,
              rating: avaliacao,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EEEE),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),

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
                  Text("⭐ $avaliacao  •  $categoriaTexto"),
                  Text("50–60 min  •  R\$ 5,00"),
                  Text(
                    descricaoExtra,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 18),
          ],
        ),
      ),
    );
  }
}
