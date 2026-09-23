import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../cliente/tela_perfil_prestador.dart';
import '../../repositories/categoria_repository.dart';
import '../../utils/usuario_util.dart';

class CategoriaServicos extends StatefulWidget {
  final String? categoriaSelecionada;
  final String tituloCategoria;

  const CategoriaServicos({
    super.key,
    this.categoriaSelecionada,
    this.tituloCategoria = "Serviços",
  });

  @override
  State<CategoriaServicos> createState() => _CategoriaServicosState();
}

class _CategoriaServicosState extends State<CategoriaServicos> {
  String pesquisa = "";
  final TextEditingController _searchController = TextEditingController();
  final CategoriaRepository _categoriaRepository = CategoriaRepository();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _removerAcentos(String texto) {
    var comAcento = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÌÍÎÏìíîïÙÚÛÜùúûüÿÑñÇç';
    var semAcento = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeIIIIiiiiUUUUuuuuyNnCc';
    String resultado = texto;
    for (int i = 0; i < comAcento.length; i++) {
      resultado = resultado.replaceAll(comAcento[i], semAcento[i]);
    }
    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    final queryNormalized = _removerAcentos(pesquisa.trim().toLowerCase());

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
        title: Text(
          widget.tituloCategoria,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ── Campo de Pesquisa ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => pesquisa = v),
                decoration: InputDecoration(
                  icon: const Icon(Icons.search),
                  hintText: "Pesquisar por nome ou serviço...",
                  border: InputBorder.none,
                  suffixIcon: pesquisa.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => pesquisa = "");
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // ── Lista de Prestadores ──
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
                  if (queryNormalized.isEmpty) return true;

                  final data = doc.data() as Map<String, dynamic>;
                  final nome = (data["nome"] ?? "").toString();
                  final sobrenome = (data["sobrenome"] ?? "").toString();
                  final nomeCompleto = "$nome $sobrenome".trim();
                  final areaAtuacao = (data["areaAtuacao"] ?? "").toString();
                  final descricao =
                      (data["descricaoServicos"] ?? data["descricao"] ?? "").toString();
                  final outrosNomes =
                      (data["nomeprestadorServicos"] ?? data["razaoSocial"] ?? "").toString();

                  final textoParaBusca = _removerAcentos(
                    "$nomeCompleto $areaAtuacao $descricao $outrosNomes".toLowerCase(),
                  );

                  return textoParaBusca.contains(queryNormalized);
                }).toList();

                docs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;

                  final mediaA =
                      (dataA['mediaEstrelas'] ?? dataA['mediaAvaliacoes'] ?? 0.0) as num;
                  final mediaB =
                      (dataB['mediaEstrelas'] ?? dataB['mediaAvaliacoes'] ?? 0.0) as num;

                  final cmpMedia = mediaB.compareTo(mediaA);
                  if (cmpMedia != 0) return cmpMedia;

                  final qtdA = (dataA['quantidadeAvaliacoes'] as num?)?.toInt() ?? 0;
                  final qtdB = (dataB['quantidadeAvaliacoes'] as num?)?.toInt() ?? 0;

                  return qtdB.compareTo(qtdA);
                });

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            pesquisa.isNotEmpty
                                ? "Nenhum prestador encontrado para \"$pesquisa\""
                                : "Nenhum serviço disponível no momento.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (pesquisa.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            const Text(
                              "Tente buscar pelo nome do profissional ou especialidade (ex: pintor, eletricista, aulas...).",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => pesquisa = "");
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text("Limpar busca"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF673AB7),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final nomeCompleto = UsuarioUtil.getNomeCompleto(
                      data,
                      tipo: 'prestador',
                      colecao: 'prestadorServicos',
                    );
                    final areaAtuacao = (data["areaAtuacao"] ?? "").toString().trim();
                    final telefone =
                        (data["telefone"] ?? "Não informado").toString();
                    final bool isOnline = data["isOnline"] ?? false;

                    final fotoUrl = (data["fotoPerfilUrl"] ??
                        data["fotoUrl"] ??
                        data["imagemUrl"] ??
                        data["logoUrl"]) as String?;

                    return _buildLojaCard(
                      context: context,
                      lojaId: docs[index].id,
                      nome: nomeCompleto,
                      areaAtuacao: areaAtuacao,
                      telefone: telefone,
                      isOnline: isOnline,
                      fotoUrl: fotoUrl,
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
    required bool isOnline,
    String? fotoUrl,
    String? areaAtuacao,
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
                shape: BoxShape.circle,
              ),
              child: (fotoUrl != null && fotoUrl.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: UsuarioUtil.buildImageWidget(
                        fotoUrl,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.person, color: Colors.grey, size: 34),
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
                  if (areaAtuacao != null && areaAtuacao.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        areaAtuacao,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: isOnline ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOnline ? "Online" : "Offline",
                        style: TextStyle(
                          fontSize: 12,
                          color: isOnline ? Colors.green[700] : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
