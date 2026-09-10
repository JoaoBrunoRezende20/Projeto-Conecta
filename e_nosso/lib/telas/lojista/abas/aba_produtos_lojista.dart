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
        ),
      ),
    );
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

  Future<void> _atualizarEstoque(Produto produto, int delta) async {
    int novoEstoque = produto.estoque + delta;
    if (novoEstoque < 0) novoEstoque = 0;
    await _produtoRepository.atualizarEstoque(produto.id, novoEstoque);
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
            const SizedBox(height: 16),
            const Text(
              "Gerencie seus produtos: edite características, fotos, estoque e controle a disponibilidade.",
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Imagem do Produto
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: temImagem
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: UsuarioUtil.buildImageWidget(
                      produto.imagemUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 30),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    produto.estoque > 0 ? "Disponível" : "Indisponível",
                    style: TextStyle(
                      color: produto.estoque > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Controles (Editar, +/- Estoque, Excluir)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                      size: 22,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _atualizarEstoque(produto, -1),
                  ),
                  Text(
                    produto.estoque.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.green,
                      size: 22,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _atualizarEstoque(produto, 1),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
        ],
      ),
    );
  }
}

