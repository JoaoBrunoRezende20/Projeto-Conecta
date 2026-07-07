import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../cliente/tela_produtos_disponiveis.dart';
import '../../repositories/categoria_repository.dart';

class CategoriaComidas extends StatefulWidget {
  const CategoriaComidas({super.key});

  @override
  State<CategoriaComidas> createState() => _CategoriaComidasState();
}

class _CategoriaComidasState extends State<CategoriaComidas> {
  String pesquisa = "";
  final CategoriaRepository _categoriaRepository = CategoriaRepository();

  Widget _buildFiltro(String nomeCategoria) {
    return Tab(
      height: 35,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.shade300, width: 1.5), 
        ),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            nomeCategoria,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: const Text("Produtos", style: TextStyle(color: Colors.black)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: TabBar(
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Colors.red,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              tabs: [
                _buildFiltro("Todos"),
                _buildFiltro("🛒 Feira Livre"),
                _buildFiltro("🥖 Quitandas"),
                _buildFiltro("🥤 Bebidas"),
                _buildFiltro("📦 Outros"),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            // Barra de pesquisa
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
                  hintText: "Pesquisar loja...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // Lista
          Expanded(
            child: TabBarView(
              children: [
                _buildLista(null),
                _buildLista('Feira Livre'),
                _buildLista('Comidas'),
                _buildLista('Bebidas'),
                _buildLista('Outros'),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildLista(String? categoria) {
    Stream<QuerySnapshot> stream = categoria == null
        ? _categoriaRepository.getTodosLojistas()
        : _categoriaRepository.getLojistasPorCategoria(categoria);

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("Erro ao carregar lojas. Tente novamente mais tarde."),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Nenhuma loja encontrada."));
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final nome = (data['razaoSocial'] ?? data['nomeLojista'] ?? '')
              .toString()
              .toLowerCase();
          return nome.contains(pesquisa.toLowerCase());
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text("Nenhuma loja encontrada."));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final nome = (data['razaoSocial'] ?? data['nomeLojista'] ?? 'Loja sem nome').toString();
            final descricao = (data['descricao'] ?? 'Sem descrição').toString();

            return _buildLojaCard(
              context: context,
              lojaId: docs[index].id,
              nome: nome,
              categoriaTexto: categoria ?? "Loja",
              descricaoExtra: descricao,
              avaliacao: 5.0,
            );
          },
        );
      },
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
