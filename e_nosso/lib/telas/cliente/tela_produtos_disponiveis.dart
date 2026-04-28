import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// IMPORTANTE: Importando o seu arquivo externo de carrinho
import 'tela_carrinho.dart';
import 'tela_detalhes_produto.dart';
import '../../utils/carrinho_util.dart';

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
  @override
  void initState() {
    super.initState();
    _carregarCarrinhoSalvo();
  }

  Future<void> _carregarCarrinhoSalvo() async {
    final dadosSalvos = await CarrinhoUtil.carregarCarrinho();
    
    final lojaSalva = dadosSalvos['lojaId'] as String?;
    final carrinhoSalvo = dadosSalvos['carrinho'] as Map<String, Map<String, dynamic>>?;

    // Se o usuário entrar numa loja diferente da que estava salva
    if (lojaSalva != null && lojaSalva != widget.lojaId) {
      carrinhoGlobal.clear();
      lojaIdDoCarrinho = widget.lojaId;
      await CarrinhoUtil.salvarCarrinho(carrinhoGlobal, lojaIdDoCarrinho);
    } else {
      // Se for a mesma loja ou vazio, recuperamos os dados salvos
      lojaIdDoCarrinho = widget.lojaId;
      if (carrinhoSalvo != null && carrinhoSalvo.isNotEmpty) {
        carrinhoGlobal.clear();
        carrinhoGlobal.addAll(carrinhoSalvo);
      }
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
      bottomNavigationBar: carrinhoGlobal.isNotEmpty
          ? _buildBarraCarrinho()
          : null,
    );
  }

  Widget _buildListaProdutos() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('produtos')
          .where('lojistaId', isEqualTo: widget.lojaId)
          .snapshots(),
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
    final int quantidadeNoCarrinho = carrinhoGlobal[id]?['quantidade'] ?? 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TelaDetalhesProduto(produto: {...produto, 'id': id}),
          ),
        ).then((_) => setState(() {})); // Atualiza a lista ao voltar
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produto["nome"] ?? "Produto",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    estoqueDisponivel > 0
                        ? "$estoqueDisponivel unidades disponíveis"
                        : "Esgotado",
                    style: TextStyle(
                      fontSize: 12,
                      color: estoqueDisponivel < 5
                          ? Colors.orange[900]
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "R\$ ${(produto["preco"] ?? 0).toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
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
                        setState(() {
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
