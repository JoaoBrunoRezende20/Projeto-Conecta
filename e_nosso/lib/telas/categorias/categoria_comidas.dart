import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../cliente/tela_produtos_disponiveis.dart';
import '../../repositories/categoria_repository.dart';
import '../../repositories/usuario_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CategoriaComidas extends StatefulWidget {
  final String? categoriaSelecionada;
  final String tituloCategoria;

  const CategoriaComidas({
    super.key,
    this.categoriaSelecionada,
    this.tituloCategoria = "Produtos",
  });

  @override
  State<CategoriaComidas> createState() => _CategoriaComidasState();
}

class _CategoriaComidasState extends State<CategoriaComidas> {
  String pesquisa = "";
  final CategoriaRepository _categoriaRepository = CategoriaRepository();
  final UsuarioRepository _usuarioRepository = UsuarioRepository();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

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
        title: Text(widget.tituloCategoria, style: const TextStyle(color: Colors.black)),
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
            child: _buildLista(widget.categoriaSelecionada),
          ),
        ],
      ),
    );
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

        // Se o usuário estiver logado, precisamos escutar os favoritos para atualizar as estrelas
        if (_uid != null) {
          return StreamBuilder<DocumentSnapshot>(
            stream: _usuarioRepository.getUsuarioStream(_uid, 'usuarioComum'),
            builder: (context, userSnapshot) {
              final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
              final List<String> lojasFavoritas = List<String>.from(userData?['lojasFavoritas'] ?? []);

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final nome = (data['razaoSocial'] ?? data['nomeLojista'] ?? 'Loja sem nome').toString();
                  final descricao = (data['descricao'] ?? 'Sem descrição').toString();
                  final lojaId = docs[index].id;

                  return _buildLojaCard(
                    context: context,
                    lojaId: lojaId,
                    nome: nome,
                    categoriaTexto: categoria ?? "Loja",
                    descricaoExtra: descricao,
                    avaliacao: 5.0,
                    isFavorita: lojasFavoritas.contains(lojaId),
                  );
                },
              );
            },
          );
        }

        // Se for visitante
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
              isFavorita: false,
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
    required bool isFavorita,
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
                  const Text("50–60 min  •  R\$ 5,00"),
                  Text(
                    descricaoExtra,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),

            IconButton(
              icon: Icon(
                isFavorita ? Icons.star : Icons.star_border,
                color: isFavorita ? Colors.amber : Colors.grey,
              ),
              onPressed: () {
                if (_uid != null) {
                  if (isFavorita) {
                    _usuarioRepository.removerLojaFavorita(_uid, lojaId);
                  } else {
                    _usuarioRepository.adicionarLojaFavorita(_uid, lojaId);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Faça login para favoritar lojas.")),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
