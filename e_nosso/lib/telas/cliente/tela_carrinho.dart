import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/tela_login.dart';
import '../auth/tela_cadastro_usuarios.dart';
import 'tela_finalizacao_compra.dart';
import '../../services/carrinho_service.dart';
import '../../utils/usuario_util.dart';

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

  @override
  void initState() {
    super.initState();
    _carrinhoService.inicializar();
  }

  String? _getLojaId() {
    if (_carrinhoService.lojaId != null && _carrinhoService.lojaId!.isNotEmpty) {
      return _carrinhoService.lojaId;
    }
    if (_carrinhoService.itens.isNotEmpty) {
      final firstItem = _carrinhoService.itens.values.first;
      return (firstItem['lojaId'] as String?)?.isNotEmpty == true
          ? firstItem['lojaId'] as String
          : null;
    }
    return null;
  }

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

  Future<void> _atualizarQuantidade(String id, int delta) async {
    if (delta > 0) {
      final item = _carrinhoService.itens[id];
      final itemLojaId = (item != null ? item['lojaId'] as String? : null) ??
          _carrinhoService.lojaId ??
          '';
      final int qtdAtual = ((item?['quantidade'] ?? 0) as num).toInt();

      // Consulta o estoque atual do produto no Firestore
      try {
        final doc = await FirebaseFirestore.instance.collection('produtos').doc(id).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final int estoque = (data['estoque'] as num?)?.toInt() ?? 0;
          if (qtdAtual + delta > estoque) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    estoque <= 0
                        ? "Este produto está esgotado."
                        : "Limite de estoque atingido ($estoque unidade${estoque > 1 ? 's' : ''}).",
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            return;
          }
        }
      } catch (e) {
        debugPrint("Erro ao checar estoque no carrinho: $e");
      }

      await _carrinhoService.adicionarItem(id, {'quantidade': 1}, itemLojaId);
    } else {
      await _carrinhoService.decrementarItem(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _carrinhoService,
      builder: (context, _) {
        final String nomeLojaExibida = (_carrinhoService.isNotEmpty &&
                widget.lojaName == "Sua Sacola")
            ? (_carrinhoService.itens.values.first['lojaNome'] as String? ?? widget.lojaName)
            : widget.lojaName;

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
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          body: _carrinhoService.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        "Sua sacola está vazia",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Continuar Comprando"),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- CABEÇALHO DA LOJA ---
                      StreamBuilder<DocumentSnapshot>(
                        stream: (_getLojaId() != null && _getLojaId()!.isNotEmpty)
                            ? FirebaseFirestore.instance
                                .collection('lojistas')
                                .doc(_getLojaId())
                                .snapshots()
                            : const Stream.empty(),
                        builder: (context, snapshot) {
                          String? fotoLoja;
                          String nomeFinal = nomeLojaExibida;

                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            nomeFinal = data['razaoSocial'] ?? data['nomeFantasia'] ?? nomeFinal;
                            fotoLoja = (data['fotoPerfilUrl'] ?? data['logoUrl'] ?? data['imagemUrl']) as String?;
                          } else if (_carrinhoService.isNotEmpty) {
                            fotoLoja = _carrinhoService.itens.values.first['lojaLogoUrl'] as String?;
                          }

                          return Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: (fotoLoja != null && fotoLoja.isNotEmpty)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(30),
                                        child: UsuarioUtil.buildImageWidget(
                                          fotoLoja,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(Icons.storefront, color: Colors.black54, size: 30),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nomeFinal,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: () {
                                        if (Navigator.canPop(context)) {
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: const Text(
                                        "Adicionar mais itens",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
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
      },
    );
  }

  Widget _cardItemCarrinho(Map<String, dynamic> item, String id) {
    final double precoTotal =
        ((item['preco'] ?? 0.0) as num).toDouble() *
            ((item['quantidade'] ?? 0) as num).toInt();
    final String? imagem = (item['imagem'] ?? item['imagemUrl'] ?? item['imagemBase64'] ?? item['fotoUrl']) as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: (imagem != null && imagem.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: UsuarioUtil.buildImageWidget(
                      imagem,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
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
                      content: const Text(
                        "Você precisa entrar na sua conta ou se cadastrar para finalizar o pedido.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Cancelar"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TelaLogin(
                                  tipoUsuario: 'comum',
                                  returnOnSuccess: true,
                                ),
                              ),
                            ).then((sucesso) {
                              if (sucesso == true && mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TelaDadosEntrega(valorTotal: _total + 5),
                                  ),
                                );
                              }
                            });
                          },
                          child: const Text("Entrar"),
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
                              if (sucesso == true && mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TelaDadosEntrega(valorTotal: _total + 5),
                                  ),
                                );
                              }
                            });
                          },
                          child: const Text("Cadastrar"),
                        ),
                      ],
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TelaDadosEntrega(valorTotal: _total + 5),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A4A4A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
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
