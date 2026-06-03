import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'tela_detalhes_servico.dart';

class TelaPerfilPrestador extends StatefulWidget {
  final String prestadorId;

  const TelaPerfilPrestador({super.key, required this.prestadorId});

  @override
  State<TelaPerfilPrestador> createState() => _TelaPerfilPrestadorState();
}

class _TelaPerfilPrestadorState extends State<TelaPerfilPrestador> {
  Map<String, dynamic>? _dadosPrestador;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarPrestador();
  }

  Future<void> _carregarPrestador() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('prestadorServicos')
          .doc(widget.prestadorId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _dadosPrestador = doc.data();
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black54, width: 1.5),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dadosPrestador == null
          ? const Center(child: Text('Prestador não encontrado.'))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final data = _dadosPrestador!;
    final nome = (data['nome'] ?? data['nomeCompleto'] ?? 'Prestador').toString();
    final areaAtuacao = (data['areaAtuacao'] ?? 'Prestador autônomo').toString();
    final descricao = (data['descricaoServicos'] ?? data['descricao'] ?? data['areaAtuacao'] ?? '*Descrição geral dos serviços prestados').toString();
    final telefone = (data['telefone'] ?? 'Não informado').toString();
    final mediaAvaliacoes = (data['mediaEstrelas'] ?? data['mediaAvaliacoes'] ?? 0.0).toDouble();
    final int qtdAvaliacoes = (data['quantidadeAvaliacoes'] as num?)?.toInt() ?? 0;
    final fotoPerfilUrl = data['fotoPerfilUrl'] as String?;

    // Fotos do portfólio salvas no campo 'fotosPortfolio' como lista de URLs
    final List<dynamic> fotosRaw = data['fotosPortfolio'] ?? [];
    final List<String> fotos = fotosRaw.map((e) => e.toString()).toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cabeçalho: avatar + nome + avaliação ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: fotoPerfilUrl != null && fotoPerfilUrl.isNotEmpty
                            ? NetworkImage(fotoPerfilUrl)
                            : null,
                        child: fotoPerfilUrl == null || fotoPerfilUrl.isEmpty
                            ? const Icon(Icons.person, size: 36, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      // Nome, avaliação e tipo
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 3),
                                Text(
                                  mediaAvaliacoes > 0
                                      ? '${mediaAvaliacoes.toStringAsFixed(1)} ($qtdAvaliacoes)'
                                      : 'Sem avaliações',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              areaAtuacao,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Descrição ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Text(
                    descricao,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Botões Mensagem / Ir para catálogo ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Iniciando conversa com $nome...'),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.black38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Mensagem',
                            style: TextStyle(color: Colors.black87, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TelaDetalhesServico(
                                  prestador: {
                                    'prestadorId': widget.prestadorId,
                                    'nome': nome,
                                    'telefone': telefone,
                                  },
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.black38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Ir para catálogo',
                            style: TextStyle(color: Colors.black87, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ── Grade de fotos do portfólio ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: fotos.isNotEmpty ? fotos.length : 8,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      if (fotos.isNotEmpty && index < fotos.length) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            fotos[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        );
                      }
                      // Placeholder cinza quando não há fotos
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
