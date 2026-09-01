import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/carrinho_service.dart';
import '../../utils/usuario_util.dart';
import 'tela_carrinho.dart';

// Este widget é Stateful porque precisamos que a quantidade mude na tela
class TelaDetalhesProduto extends StatefulWidget {
  final Map<String, dynamic> produto; // Dados vindo do Firebase
  final String lojaId;

  const TelaDetalhesProduto({super.key, required this.produto, required this.lojaId});

  @override
  State<TelaDetalhesProduto> createState() => _TelaDetalhesProdutoState();
}

class _TelaDetalhesProdutoState extends State<TelaDetalhesProduto> {
  final CarrinhoService _carrinhoService = CarrinhoService();
  int quantidade = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('lojistas').doc(widget.lojaId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text("Carregando...", style: TextStyle(color: Colors.black, fontSize: 16));
            }
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final nomeDaLoja = data['razaoSocial'] ?? data['nomeFantasia'] ?? 'Loja';
              return Text(
                nomeDaLoja,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              );
            }
            return const Text("Loja", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold));
          },
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: (widget.produto['id'] != null)
            ? FirebaseFirestore.instance
                .collection('produtos')
                .doc(widget.produto['id'])
                .snapshots()
            : null,
        builder: (context, snapshot) {
          Map<String, dynamic> dadosLive = widget.produto;
          if (snapshot.hasData && snapshot.data!.exists) {
            final liveMap = snapshot.data!.data() as Map<String, dynamic>;
            dadosLive = {...liveMap, 'id': widget.produto['id']};
          }

          final int estoque = (dadosLive['estoque'] as num?)?.toInt() ?? 0;
          final bool ativo = dadosLive['ativo'] ?? true;
          final bool isIndisponivel = estoque <= 0 || !ativo;
          final String nome = dadosLive['nome'] ?? "Pão de queijo";
          final String descricao = dadosLive['descricao'] ?? "Descrição do produto";
          final double preco = ((dadosLive['preco'] ?? 0) as num).toDouble();
          final String? imagem = (dadosLive['imagemUrl'] ?? dadosLive['imagemBase64']) as String?;

          // Ajusta a quantidade automaticamente caso o estoque mude no banco
          int qtdAjustada = quantidade;
          if (isIndisponivel) {
            qtdAjustada = 0;
          } else if (qtdAjustada > estoque) {
            qtdAjustada = estoque;
          } else if (qtdAjustada <= 0 && estoque > 0) {
            qtdAjustada = 1;
          }

          const ColorFilter greyscaleFilter = ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0,      0,      0,      1, 0,
          ]);

          Widget imageWidget = (imagem != null && imagem.isNotEmpty)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: UsuarioUtil.buildImageWidget(
                    imagem,
                    fit: BoxFit.cover,
                  ),
                )
              : const Center(
                  child: Text(
                    "*imagem do produto",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                );

          if (isIndisponivel) {
            imageWidget = ColorFiltered(
              colorFilter: greyscaleFilter,
              child: imageWidget,
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  "DETALHAMENTO DOS PRODUTOS",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 25),

                // ==========================================
                // --- CARD CENTRAL PRINCIPAL ---
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white, // Fundo branco
                    border: Border.all(color: Colors.grey.shade300), // Borda cinza
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Espaço da Imagem
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: imageWidget,
                          ),
                          const SizedBox(width: 20),
                          // Infos do Produto
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nome,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isIndisponivel ? Colors.black54 : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  descricao,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isIndisponivel ? Colors.grey : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Indicador de Disponibilidade / Estoque
                                if (isIndisponivel)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.cancel_outlined, color: Colors.red, size: 13),
                                        SizedBox(width: 4),
                                        Text(
                                          "Produto Indisponível",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.inventory_2_outlined, color: Colors.green[700], size: 13),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Em estoque: $estoque un.",
                                          style: TextStyle(
                                            color: Colors.green[800],
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // ==========================================
                      // --- SELETOR DE QUANTIDADE E BOTÃO ---
                      // ==========================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Seletor de Quantidade (- Num +)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200], // Fundo cinza do mockup
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: (isIndisponivel || qtdAjustada <= 1)
                                      ? null
                                      : () => setState(() => quantidade = qtdAjustada - 1),
                                  icon: Icon(
                                    Icons.remove,
                                    size: 18,
                                    color: (isIndisponivel || qtdAjustada <= 1) ? Colors.grey : Colors.black,
                                  ),
                                ),
                                Text(
                                  "$qtdAjustada",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isIndisponivel ? Colors.grey : Colors.black,
                                  ),
                                ),
                                IconButton(
                                  onPressed: (isIndisponivel || qtdAjustada >= estoque)
                                      ? null
                                      : () => setState(() => quantidade = qtdAjustada + 1),
                                  icon: Icon(
                                    Icons.add,
                                    size: 18,
                                    color: (isIndisponivel || qtdAjustada >= estoque) ? Colors.grey : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Botão Adicionar à sacola
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isIndisponivel
                                  ? null
                                  : () {
                                      _adicionarNaSacola(dadosLive, qtdAjustada);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isIndisponivel
                                    ? Colors.grey[300]
                                    : const Color(0xFF8B9467),
                                foregroundColor: isIndisponivel ? Colors.grey[600] : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                              ),
                              child: Text(
                                isIndisponivel ? "Produto Indisponível" : "Adicionar à sacola",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

            const SizedBox(height: 35),
            const Text(
              "Adicionais",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 15),

            // ==========================================
            // --- GRID DE ADICIONAIS (MOCKUP) ---
            // ==========================================
            GridView.builder(
              shrinkWrap: true, // Necessário para rolar dentro do Column
              physics:
                  const NeverScrollableScrollPhysics(), // Desativa rolagem própria
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 por linha como no Figma
                mainAxisSpacing: 15,
                crossAxisSpacing: 10,
                childAspectRatio: 2.8, // Ajuste para altura dos itens
              ),
              itemCount: 6, // Exemplo de 6 adicionais
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Text(
                      "Adicional ${String.fromCharCode(65 + index)}",
                      style: const TextStyle(fontSize: 11),
                    ),
                    const Text(
                      "Preço \$",
                      style: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 35),
            const Text(
              "Produtos semelhantes (na loja)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 15),

            // ==========================================
            // --- LISTA HORIZONTAL (SEMELHANTES) ---
            // ==========================================
            SizedBox(
              height: 110,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('produtos')
                    .where('lojistaId', isEqualTo: widget.produto['lojistaId'])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs.where((doc) => doc.id != widget.produto['id']).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text("Nenhum produto semelhante", style: TextStyle(fontSize: 10)));
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final semelhandoData = docs[index].data() as Map<String, dynamic>;
                      final semelhandoId = docs[index].id;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TelaDetalhesProduto(
                                produto: {...semelhandoData, 'id': semelhandoId},
                                lojaId: widget.lojaId,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 15),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              // Minimagem
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: (semelhandoData['imagemUrl'] != null || semelhandoData['imagemBase64'] != null)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: UsuarioUtil.buildImageWidget(
                                          (semelhandoData['imagemUrl'] ?? semelhandoData['imagemBase64']) as String,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(Icons.image, size: 20, color: Colors.grey),
                              ),
                              const SizedBox(width: 10),
                              // Texto
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      semelhandoData['nome'] ?? "Produto",
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "R\$ ${(semelhandoData['preco'] ?? 0).toStringAsFixed(2)}",
                                      style: const TextStyle(fontSize: 9),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    },
  ),
);
}

  Future<void> _adicionarNaSacola(Map<String, dynamic> dadosLive, int qtd) async {
    final String? id = dadosLive['id'];
    if (id == null) return;

    final int estoqueAtual = (dadosLive['estoque'] as num?)?.toInt() ?? 0;
    if (estoqueAtual <= 0 || qtd <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Este produto está indisponível para compra no momento."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (qtd > estoqueAtual) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Quantidade máxima disponível em estoque: $estoqueAtual."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final itemAdicionado = {
      'nome': dadosLive['nome'] ?? 'Produto',
      'preco': dadosLive['preco'] ?? 0.0,
      'quantidade': qtd,
    };

    await _carrinhoService.adicionarItem(id, itemAdicionado, widget.lojaId);

    if (!mounted) return;
    // Buscar nome da loja para a tela de carrinho
    String storeName = "Loja";
    try {
      final doc = await FirebaseFirestore.instance.collection('lojistas').doc(widget.lojaId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        storeName = data['razaoSocial'] ?? data['nomeFantasia'] ?? "Loja";
      }
    } catch (_) {}

    if (!mounted) return;
    
    // Mostra o bottom sheet de confirmação
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text(
              "Produto adicionado!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "$quantidade x ${widget.produto['nome'] ?? 'Produto'}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Fecha modal
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TelaRevisaoCarrinho(lojaName: storeName),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Ir para o Carrinho", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context); // Fecha modal e fica na tela
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Continuar Comprando", style: TextStyle(color: Colors.black, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
