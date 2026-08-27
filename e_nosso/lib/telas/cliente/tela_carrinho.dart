import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/tela_login.dart';
import '../auth/tela_cadastro_usuarios.dart';
import 'tela_finalizacao_compra.dart';
import '../../services/carrinho_service.dart';

class TelaRevisaoCarrinho extends StatefulWidget {
  final String lojaName;

  const TelaRevisaoCarrinho({
    super.key,
    required this.lojaName,
  });

  @override
  State<TelaRevisaoCarrinho> createState() => _TelaRevisaoCarrinhoState();
}

class _TelaRevisaoCarrinhoState extends State<TelaRevisaoCarrinho> {
  final CarrinhoService _carrinhoService = CarrinhoService();

  double get _total {
    double total = 0.0;
    _carrinhoService.itens.forEach((key, value) {
      final preco = ((value['preco'] ?? 0.0) as num).toDouble();
      final qtd = ((value['quantidade'] ?? 0) as num).toInt();
      total += (preco * qtd);
    });
    return total;
  }

  int get _totalItens {
    return _carrinhoService.quantidadeTotal;
  }

  void _atualizarQuantidade(String id, int delta) {
    if (delta > 0) {
      // O item já existe, basta adicionar mais 1 na quantidade
      _carrinhoService.adicionarItem(id, {'quantidade': 1}, _carrinhoService.lojaId ?? '');
    } else {
      _carrinhoService.decrementarItem(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _carrinhoService,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              "Sacola",
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _carrinhoService.isEmpty
              ? const Center(child: Text("Sua sacola está vazia"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- CABEÇALHO DA LOJA ---
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.lojaName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Adicionar mais itens",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      // --- ITENS ADICIONADOS ---
                      const Text(
                        "Itens adicionados",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 25),
                      // LISTA DE ITENS
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _carrinhoService.itens.length,
                        itemBuilder: (context, index) {
                          final key = _carrinhoService.itens.keys.elementAt(index);
                          final item = _carrinhoService.itens[key]!;
                          return _cardItemCarrinho(item, key);
                        },
                      ),
                    ],
                  ),
                ),
          bottomNavigationBar: _carrinhoService.isEmpty ? null : _buildBottomBar(),
        );
      }
    );
  }

  Widget _cardItemCarrinho(Map<String, dynamic> item, String id) {
    final double precoTotal = ((item['preco'] ?? 0.0) as num).toDouble() * ((item['quantidade'] ?? 0) as num).toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGEM PLACEHOLDER
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 15),
          // INFOS DO PRODUTO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nome'] ?? "Produto",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  "${item['quantidade']} unidades",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "R\$ ${precoTotal.toStringAsFixed(2).replaceAll('.', ',')}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // SELETOR DE QUANTIDADE
          Container(
            height: 28,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.remove, size: 14, color: Colors.black54),
                  onPressed: () => _atualizarQuantidade(id, -1),
                ),
                Text(
                  "${item['quantidade']}",
                  style: const TextStyle(fontSize: 13),
                ),
                IconButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.add, size: 14, color: Colors.black54),
                  onPressed: () => _atualizarQuantidade(id, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total com a entrega",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    text: "R\$${_total.toStringAsFixed(2).replaceAll('.', ',')} ",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: "/ $_totalItens itens",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                final isVisitor = user == null || user.isAnonymous;

                if (isVisitor) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Autenticação necessária"),
                      content: const Text("Você precisa ter uma conta para finalizar o pedido. Deseja realizar o cadastro?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Não"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TelaCadastro(
                                  tipoUsuario: 'comum',
                                  returnOnSuccess: true,
                                ),
                              ),
                            ).then((sucesso) {
                              if (sucesso == true) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TelaDadosEntrega(valorTotal: _total + 5),
                                  ),
                                );
                              }
                            });
                          },
                          child: const Text("Sim, Cadastrar"),
                        ),
                      ],
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TelaDadosEntrega(valorTotal: _total + 5),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A4A4A), // Cinza escuro como na imagem
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                elevation: 0,
              ),
              child: const Text(
                "Continuar",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
