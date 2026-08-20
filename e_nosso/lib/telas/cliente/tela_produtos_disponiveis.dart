import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// IMPORTANTE: Importando o seu arquivo externo de carrinho
import 'tela_carrinho.dart';
import 'tela_detalhes_produto.dart';
import '../../utils/carrinho_util.dart';
import '../../repositories/produto_repository.dart';


// --- VARIÁVEIS GLOBAIS DE CARRINHO ---
// Ficam fora da classe para sobreviverem quando o utilizador sai do ecrã
final Map<String, Map<String, dynamic>> carrinhoGlobal = {};
String? lojaIdDoCarrinho;

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

  @override
  void initState() {
    super.initState();
    _carregarCarrinhoSalvo();
  }

  Future<void> _carregarCarrinhoSalvo() async {
    final dadosSalvos = await CarrinhoUtil.carregarCarrinho();

    final lojaSalva = dadosSalvos['lojaId'] as String?;
    final carrinhoSalvo =
        dadosSalvos['carrinho'] as Map<String, Map<String, dynamic>>?;

    if (carrinhoSalvo != null && carrinhoSalvo.isNotEmpty) {
      carrinhoGlobal.clear();
      carrinhoGlobal.addAll(carrinhoSalvo);
      lojaIdDoCarrinho = lojaSalva;
    } else {
      lojaIdDoCarrinho = widget.lojaId;
    }

    // Atualiza a tela se necessário
    if (mounted) setState(() {});
  }

  double get _totalCarrinho {
    double total = 0.0;
    carrinhoGlobal.forEach((id, dados) {
      total += (dados['preco'] ?? 0) * dados['quantidade'];
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
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
        title: Column(
          children: [
            Text(
              widget.storeName,
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
                  widget.rating.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _buildListaProdutos(),
      bottomNavigationBar:
          (carrinhoGlobal.isNotEmpty && lojaIdDoCarrinho == widget.lojaId)
          ? _buildBarraCarrinho()
          : null,
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
    final int estoqueDisponivel = produto["estoque"] ?? 0;
    final bool isIndisponivel = estoqueDisponivel <= 0;
    final String nome = produto["nome"] ?? "Produto";
    final String descricao = produto["descricao"] ?? "Descrição do produto";
    final double preco = (produto["preco"] ?? 0).toDouble();
    final double avaliacao = (produto["avaliacao"] ?? 5.0).toDouble();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TelaDetalhesProduto(produto: {...produto, 'id': id}),
          ),
        ).then((_) => setState(() {})); // Atualiza a lista ao voltar
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2), // Fundo cinza claro como na imagem
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem placeholder
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFDFDFDF), // Cinza do box de imagem
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            // Informações do produto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descricao.trim().isEmpty
                        ? "Descrição do produto"
                        : descricao,
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
                      const Icon(
                        Icons.star_border,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        avaliacao.toStringAsFixed(1).replaceAll('.', ','),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      if (isIndisponivel) ...[
                        const SizedBox(width: 12),
                        const Text(
                          "INDISPONÍVEL",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Preço
            Text(
              "R\$${preco.toStringAsFixed(2).replaceAll('.', ',')}",
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
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
                      itens: carrinhoGlobal, // Passamos o carrinho global
                      lojaName: widget.storeName,
                    ),
                  ),
                ).then((_) {
                  // Atualiza a tela quando o utilizador volta do carrinho
                  setState(() {});
                });
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
}
