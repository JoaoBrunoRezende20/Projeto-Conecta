import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../cliente/tela_produtos_disponiveis.dart';
import '../cliente/tela_detalhes_servico.dart';
import '../cliente/tela_perfil_prestador.dart';
import '../../repositories/categoria_repository.dart';

class CategoriaServicos extends StatefulWidget {
  const CategoriaServicos({super.key});

  @override
  State<CategoriaServicos> createState() => _CategoriaServicosState();
}

class _CategoriaServicosState extends State<CategoriaServicos> {
  String pesquisa = "";
  final CategoriaRepository _categoriaRepository = CategoriaRepository();

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
        title: const Text("Serviços", style: TextStyle(color: Colors.black)),
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
                  hintText: "Pesquisar Prestador...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _categoriaRepository.getPrestadoresAprovados(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Erro ao carregar serviços. Tente novamente mais tarde.",
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Nenhum serviço encontrado."),
                  );
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
                    child: Text("Nenhum serviço encontrado."),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final nome = (data["nome"] ?? data["nomeprestadorServicos"] ?? "")
                        .toString();
                    final telefone = (data["telefone"] ?? "Não informado")
                        .toString();

                    return _buildLojaCard(
                      context: context,
                      lojaId: docs[index].id,
                      nome: nome,
                      telefone: telefone,
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
    required String telefone,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TelaPerfilPrestador(
              prestadorId: lojaId,
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 15,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        telefone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
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
