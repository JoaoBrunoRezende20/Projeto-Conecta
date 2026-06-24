import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelaAvaliacaoServico extends StatefulWidget {
  final String pedidoId;
  final String prestadorId;
  final String nomePrestador;
  final bool isLojista;

  const TelaAvaliacaoServico({
    Key? key,
    required this.pedidoId,
    required this.prestadorId,
    required this.nomePrestador,
    this.isLojista = false,
  }) : super(key: key);

  @override
  State<TelaAvaliacaoServico> createState() => _TelaAvaliacaoServicoState();
}

class _TelaAvaliacaoServicoState extends State<TelaAvaliacaoServico> {
  double _nota = 0.0;
  final TextEditingController _comentarioController = TextEditingController();
  bool? _gostouEntrega; // null = nenhum selecionado
  bool _isSaving = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.menu, color: Colors.black),
        title: Text(
          widget.isLojista ? 'Avaliar loja' : 'Avaliar serviço',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
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
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Seção de avaliação por estrelas ──
                const Text(
                  'O que você achou do item?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _nota.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 5 estrelas interativas
                    Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _nota = starValue.toDouble()),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(
                              _nota >= starValue
                                  ? Icons.star
                                  : Icons.star_border,
                              color: _nota >= starValue
                                  ? Colors.amber
                                  : Colors.black54,
                              size: 28,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Campo de comentário ──
                const Text(
                  'Deixe seu comentário!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 90,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black38, width: 1.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TextField(
                    controller: _comentarioController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Entrega: Sim / Não ──
                const Text(
                  'Você gostou da entrega?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Botão NÃO
                    GestureDetector(
                      onTap: () => setState(() => _gostouEntrega = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _gostouEntrega == false
                              ? Colors.red.shade50
                              : Colors.white,
                          border: Border.all(
                            color: _gostouEntrega == false
                                ? Colors.red
                                : Colors.black54,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Não',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _gostouEntrega == false
                                    ? Colors.red
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.thumb_down,
                              size: 18,
                              color: _gostouEntrega == false
                                  ? Colors.red
                                  : Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Botão SIM
                    GestureDetector(
                      onTap: () => setState(() => _gostouEntrega = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _gostouEntrega == true
                              ? Colors.green
                              : Colors.white,
                          border: Border.all(
                            color: _gostouEntrega == true
                                ? Colors.green
                                : Colors.black54,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Sim',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _gostouEntrega == true
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.thumb_up,
                              size: 18,
                              color: _gostouEntrega == true
                                  ? Colors.white
                                  : Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // ── Botão Enviar Avaliação ──
                Center(
                  child: SizedBox(
                    width: 220,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _salvarAvaliacao,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        disabledBackgroundColor: Colors.grey[400],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Enviar avaliação',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Botão Voltar a tela inicial ──
                Center(
                  child: SizedBox(
                    width: 220,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[700]!, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Voltar a tela inicial',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ── Botão azul flutuante (canto inferior esquerdo) ──
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _salvarAvaliacao() async {
    // ── Validações ──
    if (_nota == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma nota antes de enviar.'),
        ),
      );
      return;
    }
    if (_gostouEntrega == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe se gostou da entrega.'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final firestore = FirebaseFirestore.instance;
    final prestadorRef = firestore
        .collection(widget.isLojista ? 'lojistas' : 'prestadorServicos')
        .doc(widget.prestadorId);
    final avaliacoesRef = prestadorRef.collection('avaliacoes');
    final pedidoRef = firestore.collection('pedidos').doc(widget.pedidoId);

    try {
      await firestore.runTransaction((transaction) async {
        // 1. Lê o documento atual do prestador para recalcular a média
        final prestadorSnap = await transaction.get(prestadorRef);
        final dadosAtuais = prestadorSnap.data() ?? {};

        final int qtdAtual =
            (dadosAtuais['quantidadeAvaliacoes'] as num?)?.toInt() ?? 0;
        final double mediaAtual =
            (dadosAtuais['mediaEstrelas'] as num?)?.toDouble() ?? 0.0;

        // 2. Calcula nova média incremental
        final int novaQtd = qtdAtual + 1;
        final double novaMedia = ((mediaAtual * qtdAtual) + _nota) / novaQtd;

        // 3. Cria o documento de avaliação na sub-coleção
        final novaAvaliacaoRef = avaliacoesRef.doc();
        transaction.set(novaAvaliacaoRef, {
          'nota': _nota,
          'clienteId': user.uid,
          'comentario': _comentarioController.text.trim(),
          'gostouEntrega': _gostouEntrega,
          'data': FieldValue.serverTimestamp(),
        });

        // 4. Atualiza mediaEstrelas e quantidadeAvaliacoes no prestador
        transaction.update(prestadorRef, {
          'mediaEstrelas': double.parse(novaMedia.toStringAsFixed(2)),
          'quantidadeAvaliacoes': novaQtd,
        });

        // 5. Marca o pedido como avaliado
        transaction.update(pedidoRef, {'avaliado': true});
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avaliação enviada com sucesso! Obrigado.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao enviar avaliação: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
