import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/carrinho_service.dart';
import 'tela_carrinho.dart';
import 'tela_detalhes_produto.dart';
import '../../repositories/produto_repository.dart';
import '../../utils/usuario_util.dart';

// --- TELA DE PRODUTOS DISPONÍVEIS ---
class TelaProdutosDisponiveis extends StatefulWidget {
  final String lojaId;
  final String storeName;
  final double rating;

  const TelaProdutosDisponiveis({
    super.key,
    required this.lojaId,
    required this.storeName,
    required this.rating,
  });

  @override
  State<TelaProdutosDisponiveis> createState() =>
      _TelaProdutosDisponiveisState();
}

class _TelaProdutosDisponiveisState extends State<TelaProdutosDisponiveis> {
  final ProdutoRepository _produtoRepository = ProdutoRepository();
  final CarrinhoService _carrinhoService = CarrinhoService();

  @override
  void initState() {
    super.initState();
    // Garante que o serviço do carrinho foi inicializado com dados locais
    _carrinhoService.inicializar();
  }

  double get _totalCarrinho {
    double total = 0.0;
    _carrinhoService.itens.forEach((id, dados) {
      total += ((dados['preco'] ?? 0) as num).toDouble() * ((dados['quantidade'] ?? 0) as num).toInt();
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _carrinhoService,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('lojistas')
                  .doc(widget.lojaId)
                  .snapshots(),
              builder: (context, snapshot) {
                double liveRating = widget.rating;
                int qtdAvaliacoes = 0;
                String liveName = widget.storeName;

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  liveRating = ((data['mediaEstrelas'] ?? data['avaliacao'] ?? widget.rating) as num).toDouble();
                  qtdAvaliacoes = (data['quantidadeAvaliacoes'] as num?)?.toInt() ?? 0;
                  liveName = data['razaoSocial'] ?? data['nomeFantasia'] ?? widget.storeName;
                }

                return InkWell(
                  onTap: () => _mostrarModalAvaliacoes(context, liveName, liveRating, qtdAvaliacoes),
                  child: Column(
                    children: [
                      Text(
                        liveName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            liveRating > 0 ? liveRating.toStringAsFixed(1) : "Novo",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (qtdAvaliacoes > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              "($qtdAvaliacoes)",
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ],
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          body: _buildListaProdutos(),
          bottomNavigationBar:
              (_carrinhoService.isNotEmpty && _carrinhoService.lojaId == widget.lojaId)
              ? _buildBarraCarrinho()
              : null,
        );
      }
    );
  }

  Widget _buildListaProdutos() {
    return StreamBuilder<QuerySnapshot>(
      stream: _produtoRepository.getProdutosPorLojista(widget.lojaId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Erro ao carregar produtos.",
              style: TextStyle(color: Colors.red[800]),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("Nenhum produto encontrado."));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            top: 12,
            bottom: 100,
          ),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final produto = doc.data() as Map<String, dynamic>;
            final produtoId = doc.id;
            return _produtoCard(produto, produtoId);
          },
        );
      },
    );
  }

  Widget _produtoCard(Map<String, dynamic> produto, String id) {
    final int estoqueDisponivel = (produto["estoque"] as num?)?.toInt() ?? 0;
    final bool ativo = produto["ativo"] ?? true;
    final bool isIndisponivel = estoqueDisponivel <= 0 || !ativo;
    final String nome = produto["nome"] ?? "Produto";
    final String descricao = produto["descricao"] ?? "Descrição do produto";
    final double preco = ((produto["preco"] ?? 0) as num).toDouble();
    final double avaliacao = ((produto["avaliacao"] ?? 5.0) as num).toDouble();
    final String? imagem = (produto["imagemUrl"] ?? produto["imagemBase64"]) as String?;

    const ColorFilter greyscaleFilter = ColorFilter.matrix(<double>[
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0,      0,      0,      1, 0,
    ]);

    Widget imageWidget = (imagem != null && imagem.isNotEmpty)
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: UsuarioUtil.buildImageWidget(imagem, fit: BoxFit.cover),
          )
        : Container(
            decoration: BoxDecoration(
              color: const Color(0xFFDFDFDF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 28),
          );

    if (isIndisponivel) {
      imageWidget = ColorFiltered(
        colorFilter: greyscaleFilter,
        child: imageWidget,
      );
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TelaDetalhesProduto(produto: {...produto, 'id': id}, lojaId: widget.lojaId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: imageWidget,
                ),
                if (isIndisponivel)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "ESGOTADO",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isIndisponivel ? Colors.black54 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descricao.trim().isEmpty ? "Descrição do produto" : descricao,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isIndisponivel ? Icons.cancel_outlined : Icons.inventory_2_outlined,
                        size: 13,
                        color: isIndisponivel ? Colors.red : Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isIndisponivel
                            ? "Indisponível"
                            : "$estoqueDisponivel em estoque",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isIndisponivel ? Colors.red : Colors.green[800],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star,
                        size: 13,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        avaliacao.toStringAsFixed(1).replaceAll('.', ','),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "R\$${preco.toStringAsFixed(2).replaceAll('.', ',')}",
              style: TextStyle(
                color: isIndisponivel ? Colors.grey : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraCarrinho() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total estimado",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  "R\$ ${_totalCarrinho.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TelaRevisaoCarrinho(
                      lojaName: widget.storeName,
                    ),
                  ),
                );
              },
              child: const Text(
                "Ver Carrinho",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarModalAvaliacoes(BuildContext context, String nomeLoja, double media, int total) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Avaliações de $nomeLoja",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              media > 0 ? media.toStringAsFixed(1) : "Sem avaliações",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (total > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                "($total avaliações)",
                                style: const TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 25),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('avaliacoes')
                      .where('alvoId', isEqualTo: widget.lojaId)
                      .orderBy('data', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "Esta loja ainda não possui comentários.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    final reviews = snapshot.data!.docs;
                    return ListView.separated(
                      itemCount: reviews.length,
                      separatorBuilder: (_, index) => const Divider(),
                      itemBuilder: (context, i) {
                        final r = reviews[i].data() as Map<String, dynamic>;
                        final double stars = ((r['estrelas'] ?? 5) as num).toDouble();
                        final String autor = r['nomeAvaliador'] ?? 'Cliente';
                        final String comentario = r['comentario'] ?? '';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              Text(autor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const Spacer(),
                              ...List.generate(5, (starIndex) {
                                return Icon(
                                  starIndex < stars ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 14,
                                );
                              }),
                            ],
                          ),
                          subtitle: comentario.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(comentario, style: const TextStyle(color: Colors.black87, fontSize: 13)),
                                )
                              : null,
                        );
                      },
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
