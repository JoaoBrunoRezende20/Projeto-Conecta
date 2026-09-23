import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/carrinho_service.dart';
import '../../utils/usuario_util.dart';
import 'tela_carrinho.dart';

// Este widget é Stateful porque precisamos que a quantidade mude na tela
class TelaDetalhesProduto extends StatefulWidget {
  final Map<String, dynamic> produto; // Dados vindo do Firebase
  final String lojaId;

  const TelaDetalhesProduto({
    super.key,
    required this.produto,
    required this.lojaId,
  });

  @override
  State<TelaDetalhesProduto> createState() => _TelaDetalhesProdutoState();
}

class _TelaDetalhesProdutoState extends State<TelaDetalhesProduto> {
  final CarrinhoService _carrinhoService = CarrinhoService();
  int quantidade = 1;
  final Set<int> _adicionaisSelecionados = {};

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
          future: FirebaseFirestore.instance
              .collection('lojistas')
              .doc(widget.lojaId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                "Carregando...",
                style: TextStyle(color: Colors.black, fontSize: 16),
              );
            }
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final nomeDaLoja =
                  data['razaoSocial'] ?? data['nomeFantasia'] ?? 'Loja';
              return Text(
                nomeDaLoja,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
            return const Text(
              "Loja",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            );
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
          final bool isIndisponivel = (estoque <= 0 && dadosLive.containsKey('estoque')) || !ativo;
          final String nome = dadosLive['nome'] ?? "Pão de queijo";
          final String descricao =
              dadosLive['descricao'] ?? "Descrição do produto";
          final double precoBase = ((dadosLive['preco'] ?? 0) as num).toDouble();
          final String? imagem =
              (dadosLive['imagemUrl'] ?? dadosLive['imagemBase64']) as String?;

          final rawAds = dadosLive['adicionais'];
          final List<Map<String, dynamic>> adicionais = (rawAds is List)
              ? rawAds
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : [];

          double somaAdicionais = 0.0;
          for (int i = 0; i < adicionais.length; i++) {
            if (_adicionaisSelecionados.contains(i)) {
              somaAdicionais += ((adicionais[i]['preco'] ?? 0) as num).toDouble();
            }
          }
          final double precoUnitarioComAdicionais = precoBase + somaAdicionais;

          final String? idProduto = dadosLive['id'] ?? widget.produto['id'];
          int qtdJaNaSacola = 0;
          if (idProduto != null) {
            _carrinhoService.itens.forEach((k, v) {
              if (k == idProduto || v['produtoId'] == idProduto) {
                qtdJaNaSacola += ((v['quantidade'] ?? 0) as num).toInt();
              }
            });
          }
          final int disponivelRestante = (estoque - qtdJaNaSacola).clamp(
            0,
            estoque,
          );
          final bool limiteSacolaAtingido =
              !isIndisponivel && qtdJaNaSacola >= estoque;

          // Ajusta a quantidade automaticamente caso o estoque ou carrinho mudem
          int qtdAjustada = quantidade;
          if (isIndisponivel || limiteSacolaAtingido) {
            qtdAjustada = 0;
          } else if (qtdAjustada > disponivelRestante) {
            qtdAjustada = disponivelRestante;
          } else if (qtdAjustada <= 0 && disponivelRestante > 0) {
            qtdAjustada = 1;
          }

          final double valorTotalCalculado = precoUnitarioComAdicionais * qtdAjustada;

          const ColorFilter greyscaleFilter = ColorFilter.matrix(<double>[
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
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
                    style: TextStyle(fontSize: 10, color: Colors.grey),
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
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ), // Borda cinza
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
                                    color: isIndisponivel
                                        ? Colors.black54
                                        : Colors.black,
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
                                if (somaAdicionais > 0)
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        "R\$ ${precoUnitarioComAdicionais.toStringAsFixed(2).replaceAll('.', ',')}",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isIndisponivel
                                              ? Colors.grey
                                              : Colors.black87,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: Colors.green.shade200,
                                          ),
                                        ),
                                        child: Text(
                                          "+ R\$ ${somaAdicionais.toStringAsFixed(2).replaceAll('.', ',')} adicionais",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    "R\$ ${precoBase.toStringAsFixed(2).replaceAll('.', ',')}",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: isIndisponivel
                                          ? Colors.grey
                                          : Colors.black87,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                // Indicador de Disponibilidade / Estoque
                                if (isIndisponivel)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.red.shade200,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.cancel_outlined,
                                          color: Colors.red,
                                          size: 13,
                                        ),
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
                                else ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.green.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          color: Colors.green[700],
                                          size: 13,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Disponível",
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
                                  onPressed:
                                      (isIndisponivel ||
                                          limiteSacolaAtingido ||
                                          qtdAjustada <= 1)
                                      ? null
                                      : () => setState(
                                          () => quantidade = qtdAjustada - 1,
                                        ),
                                  icon: Icon(
                                    Icons.remove,
                                    size: 18,
                                    color:
                                        (isIndisponivel ||
                                            limiteSacolaAtingido ||
                                            qtdAjustada <= 1)
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                Text(
                                  "$qtdAjustada",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color:
                                        (isIndisponivel || limiteSacolaAtingido)
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                IconButton(
                                  onPressed: (isIndisponivel ||
                                          limiteSacolaAtingido ||
                                          qtdAjustada >= disponivelRestante)
                                      ? null
                                      : () => setState(
                                          () => quantidade = qtdAjustada + 1,
                                        ),
                                  icon: Icon(
                                    Icons.add,
                                    size: 18,
                                    color: (isIndisponivel ||
                                            limiteSacolaAtingido ||
                                            qtdAjustada >= disponivelRestante)
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Botão Adicionar à sacola
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  (isIndisponivel || limiteSacolaAtingido)
                                  ? null
                                  : () {
                                      _adicionarNaSacola(
                                        dadosLive,
                                        qtdAjustada,
                                        adicionais,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    (isIndisponivel || limiteSacolaAtingido)
                                    ? Colors.grey[300]
                                    : const Color(0xFF8B9467),
                                foregroundColor:
                                    (isIndisponivel || limiteSacolaAtingido)
                                    ? Colors.grey[600]
                                    : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                              ),
                              child: Text(
                                isIndisponivel
                                    ? "Produto Indisponível"
                                    : (limiteSacolaAtingido
                                          ? "Limite na Sacola Atingido"
                                          : (qtdAjustada > 0
                                              ? "Adicionar à sacola • R\$ ${valorTotalCalculado.toStringAsFixed(2).replaceAll('.', ',')}"
                                              : "Adicionar à sacola")),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // --- SEÇÃO DE ADICIONAIS ---
                // ==========================================
                if (adicionais.isNotEmpty) ...[
                  const SizedBox(height: 35),
                  Row(
                    children: [
                      const Text(
                        "Adicionais",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_adicionaisSelecionados.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B9467),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${_adicionaisSelecionados.length} selecionado${_adicionaisSelecionados.length > 1 ? 's' : ''}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: adicionais.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final ad = adicionais[index];
                        final double precoAd =
                            ((ad['preco'] ?? 0) as num).toDouble();
                        final bool isSelecionado =
                            _adicionaisSelecionados.contains(index);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelecionado
                                ? const Color(0xFFF4F6EC)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelecionado
                                    ? Icons.check_circle
                                    : Icons.add_circle_outline,
                                color: isSelecionado
                                    ? const Color(0xFF8B9467)
                                    : Colors.grey.shade400,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ad['nome'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelecionado
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '+ R\$ ${precoAd.toStringAsFixed(2).replaceAll('.', ',')}',
                                      style: const TextStyle(
                                        color: Color(0xFF5A6635),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isSelecionado)
                                ElevatedButton.icon(
                                  onPressed: isIndisponivel
                                      ? null
                                      : () {
                                          setState(() {
                                            _adicionaisSelecionados.remove(index);
                                          });
                                        },
                                  icon: const Icon(Icons.remove, size: 14),
                                  label: const Text(
                                    "Remover",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade50,
                                    foregroundColor: Colors.red.shade700,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: Colors.red.shade200,
                                      ),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: isIndisponivel
                                      ? null
                                      : () {
                                          setState(() {
                                            _adicionaisSelecionados.add(index);
                                          });
                                        },
                                  icon: const Icon(Icons.add, size: 14),
                                  label: const Text(
                                    "Adicionar",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B9467),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],

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
                        .where(
                          'lojistaId',
                          isEqualTo: widget.produto['lojistaId'],
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs
                          .where((doc) => doc.id != widget.produto['id'])
                          .toList();

                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "Nenhum produto semelhante",
                            style: TextStyle(fontSize: 10),
                          ),
                        );
                      }

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final semelhandoData =
                              docs[index].data() as Map<String, dynamic>;
                          final semelhandoId = docs[index].id;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TelaDetalhesProduto(
                                    produto: {
                                      ...semelhandoData,
                                      'id': semelhandoId,
                                    },
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
                                    child:
                                        (semelhandoData['imagemUrl'] != null ||
                                            semelhandoData['imagemBase64'] !=
                                                null)
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: UsuarioUtil.buildImageWidget(
                                              (semelhandoData['imagemUrl'] ??
                                                      semelhandoData['imagemBase64'])
                                                  as String,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.image,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Texto
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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

  Future<void> _adicionarNaSacola(
    Map<String, dynamic> dadosLive,
    int qtd,
    List<Map<String, dynamic>> adicionaisDisponiveis,
  ) async {
    final String? id = dadosLive['id'] ?? widget.produto['id'];
    if (id == null) return;

    final int estoqueAtual = (dadosLive['estoque'] as num?)?.toInt() ?? 0;
    final bool ativo = dadosLive['ativo'] ?? true;
    if ((estoqueAtual <= 0 && dadosLive.containsKey('estoque')) || !ativo || qtd <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Este produto está indisponível para compra no momento.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int qtdJaNaSacola = 0;
    _carrinhoService.itens.forEach((k, v) {
      if (k == id || v['produtoId'] == id) {
        qtdJaNaSacola += ((v['quantidade'] ?? 0) as num).toInt();
      }
    });
    final int totalAposAdicionar = qtdJaNaSacola + qtd;

    if (totalAposAdicionar > estoqueAtual) {
      final int disponivelRestante = (estoqueAtual - qtdJaNaSacola).clamp(
        0,
        estoqueAtual,
      );
      String msg;
      if (disponivelRestante <= 0) {
        msg =
            "Você já adicionou todas as $estoqueAtual unidades disponíveis deste item na sacola.";
      } else {
        msg =
            "Você já possui $qtdJaNaSacola unidade(s) na sacola. Restam apenas $disponivelRestante unidade(s) disponíveis para adicionar.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.orange),
      );
      return;
    }

    // Buscar nome e logo da loja para salvar nos metadados do item e passar para o carrinho
    String storeName = "Loja";
    String? storeLogo;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('lojistas')
          .doc(widget.lojaId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        storeName = data['razaoSocial'] ?? data['nomeFantasia'] ?? "Loja";
        storeLogo =
            (data['fotoPerfilUrl'] ?? data['logoUrl'] ?? data['imagemUrl'])
                as String?;
      }
    } catch (_) {}

    // REGRA DE CARRINHO UNILOJISTA: Se a sacola tiver produtos de outro estabelecimento
    if (!_carrinhoService.pertenceAMesmaLoja(widget.lojaId)) {
      if (!mounted) return;
      final String lojaAnterior = _carrinhoService.lojaNomeAtual ?? "outro estabelecimento";

      final bool? trocarLoja = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.store_mall_directory_outlined, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Sua sacola é de outra loja",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            "Você já possui itens de \"$lojaAnterior\" na sacola.\n\nPara fazer pedidos em lojas diferentes, é necessário finalizar ou limpar a compra anterior primeiro.\n\nDeseja esvaziar a sacola para adicionar os itens de \"$storeName\"?",
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Manter Sacola Anterior", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Esvaziar e Adicionar"),
            ),
          ],
        ),
      );

      if (trocarLoja != true) {
        return;
      }

      await _carrinhoService.limparCarrinho();
    }

    final List<Map<String, dynamic>> adicionaisEscolhidos = [];
    double somaAds = 0.0;
    for (int i = 0; i < adicionaisDisponiveis.length; i++) {
      if (_adicionaisSelecionados.contains(i)) {
        final ad = adicionaisDisponiveis[i];
        final double pAd = ((ad['preco'] ?? 0) as num).toDouble();
        somaAds += pAd;
        adicionaisEscolhidos.add({
          'nome': ad['nome'] ?? '',
          'preco': pAd,
        });
      }
    }

    final double precoBase = ((dadosLive['preco'] ?? 0.0) as num).toDouble();
    final double precoFinalUnitario = precoBase + somaAds;

    String cartKey = id;
    if (adicionaisEscolhidos.isNotEmpty) {
      final adsKeys = adicionaisEscolhidos.map((a) => a['nome']).join('_');
      cartKey = '${id}_ads_${adsKeys.hashCode}';
    }

    final itemAdicionado = {
      'produtoId': id,
      'nome': dadosLive['nome'] ?? 'Produto',
      'preco': precoFinalUnitario,
      'precoBase': precoBase,
      'quantidade': qtd,
      'lojaId': widget.lojaId,
      'lojaNome': storeName,
      'lojaLogoUrl': storeLogo,
      'adicionais': adicionaisEscolhidos,
      'imagem':
          (dadosLive['imagemUrl'] ??
                  dadosLive['imagemBase64'] ??
                  dadosLive['imagem'] ??
                  dadosLive['fotoUrl'])
              as String?,
    };

    await _carrinhoService.adicionarItem(cartKey, itemAdicionado, widget.lojaId);

    if (!mounted) return;

    final String nomeExibido = dadosLive['nome'] ?? 'Produto';
    final String resumoAds = adicionaisEscolhidos.isNotEmpty
        ? " (+ ${adicionaisEscolhidos.map((e) => e['nome']).join(', ')})"
        : "";

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
              "$qtd x $nomeExibido$resumoAds",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              "Total: R\$ ${(precoFinalUnitario * qtd).toStringAsFixed(2).replaceAll('.', ',')}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A6635),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Fecha modal
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TelaRevisaoCarrinho(lojaName: storeName),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Ir para o Carrinho",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context); // Fecha modal
                if (Navigator.canPop(context)) {
                  Navigator.pop(
                    context,
                  ); // Volta para a tela anterior para continuar comprando
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Continuar Comprando",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
