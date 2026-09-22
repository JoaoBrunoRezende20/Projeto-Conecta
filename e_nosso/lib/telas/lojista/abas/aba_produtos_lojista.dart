import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../repositories/produto_repository.dart';
import '../../../utils/usuario_util.dart';
import '../tela_cadastro_produto_lojista.dart';
import '../tela_cupons_lojista.dart';
import '../tela_inicial_lojista.dart'; // Para acessar a classe Produto

class AbaProdutosLojista extends StatefulWidget {
  final String lojistaId;

  const AbaProdutosLojista({super.key, required this.lojistaId});

  @override
  State<AbaProdutosLojista> createState() => _AbaProdutosLojistaState();
}

class _AbaProdutosLojistaState extends State<AbaProdutosLojista> {
  final ProdutoRepository _produtoRepository = ProdutoRepository();

  void _abrirCadastroNovoProduto(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaCadastroProdutoLojista(
          lojistaId: widget.lojistaId,
        ),
      ),
    );
  }

  void _abrirCupons(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaCuponsLojista(
          lojistaId: widget.lojistaId,
        ),
      ),
    );
  }

  void _abrirEdicaoProduto(BuildContext context, Produto produto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaCadastroProdutoLojista(
          produtoId: produto.id,
          lojistaId: widget.lojistaId,
          nomeAtual: produto.nome,
          descricaoAtual: produto.descricao,
          precoAtual: produto.preco,
          estoqueAtual: produto.estoque,
          imagemUrlAtual: produto.imagemUrl,
          ativoAtual: produto.ativo != false,
        ),
      ),
    );
  }

  Future<void> _alternarDisponibilidade(Produto produto) async {
    final bool novoStatus = !(produto.ativo != false);
    try {
      await _produtoRepository.atualizarProduto(produto.id, {
        'ativo': novoStatus,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              novoStatus
                  ? 'Produto "${produto.nome}" marcado como DISPONÍVEL.'
                  : 'Produto "${produto.nome}" marcado como INDISPONÍVEL.',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: novoStatus ? Colors.green : Colors.grey[800],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar disponibilidade: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _excluirProduto(String id, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Produto'),
        content: Text('Tem certeza que deseja excluir "$nome"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar == true) await _produtoRepository.deletarProduto(id);
  }

  void _abrirDialogoTaxaEntrega(BuildContext context, double taxaAtual) {
    final TextEditingController controller = TextEditingController(
      text: taxaAtual > 0 ? taxaAtual.toStringAsFixed(2).replaceAll('.', ',') : '0,00',
    );
    bool entregaGratis = taxaAtual == 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.delivery_dining, color: Colors.teal, size: 26),
                  SizedBox(width: 8),
                  Text("Taxa de Entrega", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Defina o valor fixo cobrado dos clientes quando escolherem receber o pedido no endereço.",
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Oferecer Entrega Grátis", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Isenta a taxa de frete para todos os pedidos da sua loja.", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    value: entregaGratis,
                    activeThumbColor: Colors.teal,
                    onChanged: (val) {
                      setModalState(() {
                        entregaGratis = val;
                        if (val) {
                          controller.text = "0,00";
                        } else if (controller.text == "0,00") {
                          controller.text = "5,00";
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  if (!entregaGratis)
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Valor do Frete (R\$)",
                        prefixText: "R\$ ",
                        hintText: "Ex: 5,00",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.teal, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    double novoValor = 0.0;
                    if (!entregaGratis) {
                      final strLimpa = controller.text.replaceAll(',', '.').trim();
                      novoValor = double.tryParse(strLimpa) ?? 0.0;
                    }

                    try {
                      await FirebaseFirestore.instance
                          .collection('lojistas')
                          .doc(widget.lojistaId)
                          .update({'taxaEntrega': novoValor});

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              novoValor == 0
                                  ? "Entrega Grátis configurada com sucesso!"
                                  : "Taxa de entrega atualizada para R\$ ${novoValor.toStringAsFixed(2).replaceAll('.', ',')}!",
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint("Erro ao atualizar taxa de entrega: $e");
                    }
                  },
                  child: const Text("Salvar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _abrirCadastroNovoProduto(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de atalho para Cupons Promocionais
            InkWell(
              onTap: () => _abrirCupons(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withAlpha(50),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.discount_outlined, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Cupons de Desconto",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "Crie códigos em % ou R\$ para seus clientes",
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Card de gestão da Taxa de Entrega
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('lojistas')
                  .doc(widget.lojistaId)
                  .snapshots(),
              builder: (context, snap) {
                final data = snap.data?.data() as Map<String, dynamic>?;
                final double taxa = ((data?['taxaEntrega'] ?? 5.0) as num).toDouble();

                return InkWell(
                  onTap: () => _abrirDialogoTaxaEntrega(context, taxa),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade700, Colors.teal.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withAlpha(50),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.delivery_dining, color: Colors.white, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    "Taxa de Entrega: ",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      taxa == 0
                                          ? "Grátis"
                                          : "R\$ ${taxa.toStringAsFixed(2).replaceAll('.', ',')}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Toque para alterar o valor de frete da sua loja",
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              "Gerencie seus produtos: edite características, fotos e controle a disponibilidade.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Expanded(child: _buildProductList()),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _produtoRepository.getProdutosPorLojista(widget.lojistaId),
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Erro ao carregar produtos: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final produtos = snapshot.data!.docs
            .map((doc) => Produto.fromFirestore(doc))
            .toList();
        if (produtos.isEmpty) {
          return const Center(
            child: Text(
              "Nenhum produto cadastrado.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          itemCount: produtos.length,
          itemBuilder: (_, i) => _buildProductTile(produtos[i]),
        );
      },
    );
  }

  Widget _buildProductTile(Produto produto) {
    final bool temImagem =
        produto.imagemUrl != null && produto.imagemUrl!.trim().isNotEmpty;
    final bool isAtivo = produto.ativo != false;

    const ColorFilter greyscaleFilter = ColorFilter.matrix(<double>[
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0,      0,      0,      1, 0,
    ]);

    Widget imgWidget = temImagem
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: UsuarioUtil.buildImageWidget(
              produto.imagemUrl!,
              fit: BoxFit.cover,
            ),
          )
        : const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 30);

    if (!isAtivo) {
      imgWidget = ColorFiltered(
        colorFilter: greyscaleFilter,
        child: Opacity(opacity: 0.6, child: imgWidget),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAtivo ? const Color(0xFFF5F5F5) : const Color(0xFFEBEBEB),
        borderRadius: BorderRadius.circular(16),
        border: isAtivo ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Imagem do Produto
          Stack(
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: imgWidget,
              ),
              if (!isAtivo)
                Positioned(
                  bottom: 2,
                  left: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "PAUSADO",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Informações do Produto
          Expanded(
            child: InkWell(
              onTap: () => _abrirEdicaoProduto(context, produto),
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produto.nome,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isAtivo ? Colors.black : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (produto.descricao.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      produto.descricao,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    "R\$ ${produto.preco.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isAtivo ? Colors.black87 : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAtivo ? Icons.check_circle : Icons.pause_circle_filled,
                        size: 13,
                        color: isAtivo ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAtivo ? "Disponível" : "Indisponível",
                        style: TextStyle(
                          color: isAtivo ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Controles (Switch de disponibilidade, Editar, Excluir)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: isAtivo ? 'Pausar venda' : 'Ativar venda',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value: isAtivo,
                        activeThumbColor: Colors.green,
                        activeTrackColor: Colors.green.shade200,
                        inactiveThumbColor: Colors.grey.shade600,
                        inactiveTrackColor: Colors.grey.shade300,
                        onChanged: (val) => _alternarDisponibilidade(produto),
                      ),
                    ),
                    Text(
                      isAtivo ? "Ativo" : "Pausado",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isAtivo ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 22),
                visualDensity: VisualDensity.compact,
                tooltip: 'Editar Produto',
                onPressed: () => _abrirEdicaoProduto(context, produto),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                visualDensity: VisualDensity.compact,
                tooltip: 'Excluir Produto',
                onPressed: () => _excluirProduto(produto.id, produto.nome),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

