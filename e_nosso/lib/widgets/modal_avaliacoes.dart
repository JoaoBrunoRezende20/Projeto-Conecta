import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ModalAvaliacoes {
  static void exibir(
    BuildContext context, {
    required String alvoId,
    required String nomeAlvo,
    required String tipoAlvo, // 'lojista' | 'prestador'
    double media = 0.0,
    int total = 0,
    bool? isDono,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModalAvaliacoesWidget(
        alvoId: alvoId,
        nomeAlvo: nomeAlvo,
        tipoAlvo: tipoAlvo,
        mediaInicial: media,
        totalInicial: total,
        isDono: isDono,
      ),
    );
  }
}

class TelaAvaliacoes extends StatelessWidget {
  final String alvoId;
  final String nomeAlvo;
  final String tipoAlvo;
  final double media;
  final int total;
  final bool? isDono;

  const TelaAvaliacoes({
    super.key,
    required this.alvoId,
    required this.nomeAlvo,
    required this.tipoAlvo,
    this.media = 0.0,
    this.total = 0,
    this.isDono,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Avaliações e Comentários',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _ConteudoAvaliacoes(
          alvoId: alvoId,
          nomeAlvo: nomeAlvo,
          tipoAlvo: tipoAlvo,
          mediaInicial: media,
          totalInicial: total,
          isDono: isDono,
          isBottomSheet: false,
        ),
      ),
    );
  }
}

class _ModalAvaliacoesWidget extends StatelessWidget {
  final String alvoId;
  final String nomeAlvo;
  final String tipoAlvo;
  final double mediaInicial;
  final int totalInicial;
  final bool? isDono;

  const _ModalAvaliacoesWidget({
    required this.alvoId,
    required this.nomeAlvo,
    required this.tipoAlvo,
    required this.mediaInicial,
    required this.totalInicial,
    this.isDono,
  });

  @override
  Widget build(BuildContext context) {
    final double alturaModal = MediaQuery.of(context).size.height * 0.80;

    return Container(
      height: alturaModal,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Expanded(
            child: _ConteudoAvaliacoes(
              alvoId: alvoId,
              nomeAlvo: nomeAlvo,
              tipoAlvo: tipoAlvo,
              mediaInicial: mediaInicial,
              totalInicial: totalInicial,
              isDono: isDono,
              isBottomSheet: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConteudoAvaliacoes extends StatelessWidget {
  final String alvoId;
  final String nomeAlvo;
  final String tipoAlvo;
  final double mediaInicial;
  final int totalInicial;
  final bool? isDono;
  final bool isBottomSheet;

  const _ConteudoAvaliacoes({
    required this.alvoId,
    required this.nomeAlvo,
    required this.tipoAlvo,
    required this.mediaInicial,
    required this.totalInicial,
    this.isDono,
    required this.isBottomSheet,
  });

  bool _verificarSeDono() {
    if (isDono != null) return isDono!;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return currentUid != null && currentUid == alvoId;
  }

  void _abrirDialogoResposta(
    BuildContext context,
    String reviewId,
    String respostaAtual,
  ) {
    final TextEditingController controller =
        TextEditingController(text: respostaAtual);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            respostaAtual.isEmpty ? "Responder Avaliação" : "Editar Resposta",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Escreva sua resposta para o cliente...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;

                try {
                  // Atualiza na coleção global
                  await FirebaseFirestore.instance
                      .collection('avaliacoes')
                      .doc(reviewId)
                      .update({
                    'resposta': text,
                    'dataResposta': FieldValue.serverTimestamp(),
                  });

                  // Atualiza também na subcoleção do alvo
                  final colecao = tipoAlvo == 'lojista'
                      ? 'lojistas'
                      : 'prestadorServicos';
                  await FirebaseFirestore.instance
                      .collection(colecao)
                      .doc(alvoId)
                      .collection('avaliacoes')
                      .doc(reviewId)
                      .set({
                    'resposta': text,
                    'dataResposta': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Resposta enviada com sucesso!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint("Erro ao salvar resposta da avaliação: $e");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Erro ao salvar resposta: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                "Enviar",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatarData(dynamic dataObj) {
    if (dataObj == null) return '';
    DateTime? dt;
    if (dataObj is Timestamp) {
      dt = dataObj.toDate();
    } else if (dataObj is String) {
      dt = DateTime.tryParse(dataObj);
    }
    if (dt == null) return '';

    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final ano = dt.year.toString();
    return '$dia/$mes/$ano';
  }

  @override
  Widget build(BuildContext context) {
    final bool usuarioIsDono = _verificarSeDono();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('avaliacoes')
          .where('alvoId', isEqualTo: alvoId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }

        final docs = snapshot.data?.docs ?? [];

        // Ordena por data decrescente de forma resiliente
        final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
        sortedDocs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final dateA = (dataA['data'] ?? dataA['createdAt']) as Timestamp?;
          final dateB = (dataB['data'] ?? dataB['createdAt']) as Timestamp?;
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });

        // Média e contagem em tempo real
        final totalReviews = sortedDocs.length;
        double mediaReviews = mediaInicial;
        if (totalReviews > 0) {
          final soma = sortedDocs.fold<double>(0.0, (acc, doc) {
            final d = doc.data() as Map<String, dynamic>;
            final n = ((d['estrelas'] ?? d['nota'] ?? 5) as num).toDouble();
            return acc + n;
          });
          mediaReviews = soma / totalReviews;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Cabeçalho com título, nota média e estrelas
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Avaliações de $nomeAlvo",
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 22),
                            const SizedBox(width: 5),
                            Text(
                              mediaReviews > 0
                                  ? mediaReviews.toStringAsFixed(1)
                                  : "Sem avaliações",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (totalReviews > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                "($totalReviews ${totalReviews == 1 ? 'avaliação' : 'avaliações'})",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isBottomSheet)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Lista de comentários
              Expanded(
                child: sortedDocs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 56,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              tipoAlvo == 'lojista'
                                  ? "Esta loja ainda não possui comentários."
                                  : "Este profissional ainda não possui comentários.",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: sortedDocs.length,
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        separatorBuilder: (context, index) =>
                            const Divider(height: 24, color: Color(0xFFEEEEEE)),
                        itemBuilder: (context, i) {
                          final r =
                              sortedDocs[i].data() as Map<String, dynamic>;
                          final reviewId = sortedDocs[i].id;
                          final double stars =
                              ((r['estrelas'] ?? r['nota'] ?? 5) as num)
                                  .toDouble();
                          final String autor = r['nomeAvaliador'] ??
                              r['nomeCliente'] ??
                              'Cliente';
                          final String comentario = r['comentario'] ?? '';
                          final String resposta = r['resposta'] ?? '';
                          final dynamic dataRaw =
                              r['data'] ?? r['createdAt'];
                          final String dataFormatada = _formatarData(dataRaw);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nome do cliente e Estrelas
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Colors.grey[200],
                                    child: Text(
                                      autor.isNotEmpty
                                          ? autor[0].toUpperCase()
                                          : 'C',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          autor,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (dataFormatada.isNotEmpty)
                                          Text(
                                            dataFormatada,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(5, (starIndex) {
                                      return Icon(
                                        starIndex < stars
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 16,
                                      );
                                    }),
                                  ),
                                ],
                              ),

                              // Texto do comentário
                              if (comentario.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    left: 4,
                                  ),
                                  child: Text(
                                    comentario,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ),

                              // Balão de resposta do Lojista/Prestador
                              if (resposta.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F7F7),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border(
                                      left: BorderSide(
                                        color: Colors.red.shade400,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.reply,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Resposta de $nomeAlvo",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              resposta,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Ação de responder ou editar resposta para o dono
                              if (usuarioIsDono)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () => _abrirDialogoResposta(
                                        context,
                                        reviewId,
                                        resposta,
                                      ),
                                      icon: Icon(
                                        resposta.isEmpty
                                            ? Icons.reply
                                            : Icons.edit_outlined,
                                        size: 14,
                                        color: Colors.blue[700],
                                      ),
                                      label: Text(
                                        resposta.isEmpty
                                            ? "Responder"
                                            : "Editar Resposta",
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
