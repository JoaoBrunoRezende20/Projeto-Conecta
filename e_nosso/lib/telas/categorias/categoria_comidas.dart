import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../cliente/tela_produtos_disponiveis.dart';
import '../../repositories/categoria_repository.dart';
import '../../repositories/usuario_repository.dart';
import '../auth/tela_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/usuario_util.dart';

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
                  final double avaliacao = ((data['mediaEstrelas'] ?? data['avaliacao'] ?? 0.0) as num).toDouble();
                  final int qtdAvaliacoes = (data['quantidadeAvaliacoes'] as num?)?.toInt() ?? 0;
                  final String? fotoUrl = (data['fotoPerfilUrl'] ?? data['imagemUrl'] ?? data['logoUrl']) as String?;
                  final cnpjStr = (data['cnpj'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
                  final isAutonomo = cnpjStr.isNotEmpty && cnpjStr.length <= 11;

                  return _buildLojaCard(
                    context: context,
                    lojaId: lojaId,
                    nome: nome,
                    categoriaTexto: categoria ?? "Loja",
                    descricaoExtra: descricao,
                    avaliacao: avaliacao,
                    qtdAvaliacoes: qtdAvaliacoes,
                    fotoUrl: fotoUrl,
                    isFavorita: lojasFavoritas.contains(lojaId),
                    isAutonomo: isAutonomo,
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
            final double avaliacao = ((data['mediaEstrelas'] ?? data['avaliacao'] ?? 0.0) as num).toDouble();
            final int qtdAvaliacoes = (data['quantidadeAvaliacoes'] as num?)?.toInt() ?? 0;
            final String? fotoUrl = (data['fotoPerfilUrl'] ?? data['imagemUrl'] ?? data['logoUrl']) as String?;
            final cnpjStr = (data['cnpj'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
            final isAutonomo = cnpjStr.isNotEmpty && cnpjStr.length <= 11;

            return _buildLojaCard(
              context: context,
              lojaId: docs[index].id,
              nome: nome,
              categoriaTexto: categoria ?? "Loja",
              descricaoExtra: descricao,
              avaliacao: avaliacao,
              qtdAvaliacoes: qtdAvaliacoes,
              fotoUrl: fotoUrl,
              isFavorita: false,
              isAutonomo: isAutonomo,
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
    required int qtdAvaliacoes,
    String? fotoUrl,
    required bool isFavorita,
    required bool isAutonomo,
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
              child: (fotoUrl != null && fotoUrl.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: UsuarioUtil.buildImageWidget(fotoUrl, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.storefront, color: Colors.grey, size: 30),
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
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 15),
                      const SizedBox(width: 3),
                      Text(
                        avaliacao > 0 ? avaliacao.toStringAsFixed(1) : "Novo",
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      if (qtdAvaliacoes > 0) ...[
                        const SizedBox(width: 3),
                        Text(
                          "($qtdAvaliacoes)",
                          style: const TextStyle(color: Colors.black54, fontSize: 11),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Text("•  $categoriaTexto", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      if (isAutonomo) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Vendedor Autônomo"),
                                content: const Text("Este lojista atua de forma autônoma (sem CNPJ cadastrado). A plataforma Conecta não se responsabiliza por emissão de nota fiscal para estas compras."),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Entendi")),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text("Autônomo", style: TextStyle(fontSize: 10, color: Colors.blue)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descricaoExtra,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  if (isFavorita) {
                    _usuarioRepository.removerLojaFavorita(user.uid, lojaId);
                  } else {
                    _usuarioRepository.adicionarLojaFavorita(user.uid, lojaId);
                  }
                } else {
                  final sucesso = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TelaLogin(
                        tipoUsuario: 'comum',
                        returnOnSuccess: true,
                      ),
                    ),
                  );

                  if (sucesso == true) {
                    final novoUser = FirebaseAuth.instance.currentUser;
                    if (novoUser != null) {
                       _usuarioRepository.adicionarLojaFavorita(novoUser.uid, lojaId);
                       if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text("Loja adicionada aos favoritos!")),
                         );
                       }
                    }
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
