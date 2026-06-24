import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Adicionado para evitar erro no FirebaseAuth

// IMPORTANTE: Importando o seu arquivo externo de carrinho
import 'tela_carrinho.dart';
import 'tela_detalhes_produto.dart';
import '../../utils/carrinho_util.dart';
import '../../repositories/produto_repository.dart';


// --- VARIÁVEIS GLOBAIS DE CARRINHO ---
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
    final carrinhoSalvo = dadosSalvos['carrinho'] as Map<String, Map<String, dynamic>>?;

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

  // >>> NOVO: WIDGET QUE DESENHA O BOTÃO DE FILTRO (PÍLULA) <<<
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
    // >>> NOVO: DEFAULT TAB CONTROLLER ENVOLVENDO A TELA <<<
    // 5 = Todos, Feira Livre, Quitandas, Bebidas, Outros
    return DefaultTabController(
      length: 5,
      child: Scaffold(
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
          // >>> NOVO: A BARRA DE FILTROS SUBSTITUINDO O FORMATO TAB PADRÃO <<<
          bottom: TabBar(
            isScrollable: true,
            labelPadding: const EdgeInsets.symmetric(horizontal: 6.0),
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.red, // Cor do filtro ativo
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
        // >>> NOVO: TAB BAR VIEW PARA ALTERNAR AS LISTAS PELO FILTRO <<<
        body: TabBarView(
          children: [
            _buildListaProdutos(categoria: null), // Mostra tudo
            _buildListaProdutos(categoria: 'Feira Livre'),
            _buildListaProdutos(categoria: 'Quitandas'),
            _buildListaProdutos(categoria: 'Bebidas'),
            _buildListaProdutos(categoria: 'Outros'),
          ],
        ),
        bottomNavigationBar: (carrinhoGlobal.isNotEmpty && lojaIdDoCarrinho == widget.lojaId)
            ? _buildBarraCarrinho()
            : null,
      ),
    );
  }

  // >>> ATUALIZADO: AGORA RECEBE A CATEGORIA E FILTRA NO FIREBASE <<<
  Widget _buildListaProdutos({String? categoria}) {
    Query query = FirebaseFirestore.instance
        .collection('produtos')
        .where('lojistaId', isEqualTo: widget.lojaId);

    // Se houver uma categoria específica selecionada, aplica o filtro
    if (categoria != null) {
      query = query.where('categoria', isEqualTo: categoria);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
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
          return const Center(child: Text("Nenhum produto nesta categoria."));
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
    
    // Variável adicionada para checar quantidade no carrinho corretamente
    final int quantidadeNoCarrinho = carrinhoGlobal[id]?['quantidade'] ?? 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TelaDetalhesProduto(produto: {...produto, 'id': id}),
          ),
        ).then((_) => setState(() {})); 
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
                      const Icon(Icons.star_border, size: 16, color: Colors.black54),
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
                      ]
                    ],
                  ),
                ],
              ),
            ),
            // Código da MAIN: Preço
            const SizedBox(width: 8),
            Text(
              "R\$${preco.toStringAsFixed(2).replaceAll('.', ',')}",
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 12),
            // Código da FEAT: Botões do Carrinho
            if (quantidadeNoCarrinho > 0)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.black,
                    ),
                    onPressed: () => setState(() {
                      if (quantidadeNoCarrinho > 1) {
                        carrinhoGlobal[id]!['quantidade']--;
                      } else {
                        carrinhoGlobal.remove(id);
                      }
                      CarrinhoUtil.salvarCarrinho(carrinhoGlobal, lojaIdDoCarrinho);
                    }),
                  ),
                  Text(
                    "$quantidadeNoCarrinho",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.green,
                    ),
                    onPressed: quantidadeNoCarrinho < estoqueDisponivel
                        ? () => setState(() {
                              carrinhoGlobal[id]!['quantidade']++;
                              CarrinhoUtil.salvarCarrinho(carrinhoGlobal, lojaIdDoCarrinho);
                            })
                        : null,
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: estoqueDisponivel > 0
                    ? () {
                        final user = FirebaseAuth.instance.currentUser;
                        final isVisitor = user == null || user.isAnonymous;
                        if (isVisitor) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Autenticação necessária"),
                              content: const Text("Por favor, faça login ou crie uma conta para adicionar produtos ao carrinho."),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        if (carrinhoGlobal.isNotEmpty && lojaIdDoCarrinho != null && lojaIdDoCarrinho != widget.lojaId) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Carrinho de outra loja"),
                              content: const Text("Seu carrinho contém itens de outra loja. Deseja esvaziar o carrinho para adicionar este item?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancelar"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // fecha dialog
                                    setState(() {
                                      carrinhoGlobal.clear();
                                      lojaIdDoCarrinho = widget.lojaId;
                                      carrinhoGlobal[id] = {
                                        'nome': produto['nome'],
                                        'preco': produto['preco'],
                                        'quantidade': 1,
                                      };
                                      CarrinhoUtil.salvarCarrinho(carrinhoGlobal, lojaIdDoCarrinho);
                                    });
                                  },
                                  child: const Text("Esvaziar e Adicionar"),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        setState(() {
                          if (carrinhoGlobal.isEmpty) {
                            lojaIdDoCarrinho = widget.lojaId;
                          }
                          carrinhoGlobal[id] = {
                            'nome': produto['nome'],
                            'preco': produto['preco'],
                            'quantidade': 1,
                          };
                          CarrinhoUtil.salvarCarrinho(carrinhoGlobal, lojaIdDoCarrinho);
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: estoqueDisponivel > 0
                      ? Colors.red
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Adicionar"),
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
                      itens: carrinhoGlobal, 
                      lojaName: widget.storeName,
                    ),
                  ),
                ).then((_) {
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