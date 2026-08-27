import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../repositories/categoria_repository.dart';
import '../../repositories/usuario_repository.dart';
import 'tela_produtos_disponiveis.dart';

class TelaLojasFavoritas extends StatefulWidget {
  const TelaLojasFavoritas({super.key});

  @override
  State<TelaLojasFavoritas> createState() => _TelaLojasFavoritasState();
}

class _TelaLojasFavoritasState extends State<TelaLojasFavoritas> {
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
        centerTitle: true,
        title: const Text("Lojas Favoritas", style: TextStyle(color: Colors.black)),
      ),
      body: _uid == null
          ? const Center(child: Text("Faça login para ver suas lojas favoritas."))
          : StreamBuilder<DocumentSnapshot>(
              stream: _usuarioRepository.getUsuarioStream(_uid, 'usuarioComum'),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const Center(child: Text("Erro ao carregar favoritos."));
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                final List<String> lojasFavoritas = List<String>.from(userData?['lojasFavoritas'] ?? []);

                if (lojasFavoritas.isEmpty) {
                  return const Center(child: Text("Você ainda não possui lojas favoritas."));
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: _categoriaRepository.getLojistasPorIds(lojasFavoritas),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(child: Text("Erro ao carregar os dados das lojas."));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("Nenhuma loja encontrada."));
                    }

                    final docs = snapshot.data!.docs;

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
                          descricaoExtra: descricao,
                          avaliacao: 5.0,
                          lojasFavoritas: lojasFavoritas,
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildLojaCard({
    required BuildContext context,
    required String lojaId,
    required String nome,
    required String descricaoExtra,
    required double avaliacao,
    required List<String> lojasFavoritas,
  }) {
    final isFavorita = lojasFavoritas.contains(lojaId);

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
                  Text("⭐ $avaliacao"),
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
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
