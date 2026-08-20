import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../repositories/produto_repository.dart';
import '../tela_inicial_lojista.dart'; // Para acessar a classe Produto

class AbaProdutosLojista extends StatefulWidget {
  final String lojistaId;

  const AbaProdutosLojista({super.key, required this.lojistaId});

  @override
  State<AbaProdutosLojista> createState() => _AbaProdutosLojistaState();
}

class _AbaProdutosLojistaState extends State<AbaProdutosLojista> {
  final ProdutoRepository _produtoRepository = ProdutoRepository();

  void _abrirDialogAdicionarProduto(BuildContext context) {
    final nomeController = TextEditingController();
    final estoqueController = TextEditingController();
    final precoController = TextEditingController();
    final descricaoController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Adicionar Produto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome do Produto'),
              ),
              TextField(
                controller: descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              TextField(
                controller: precoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Preço (R\$)'),
              ),
              TextField(
                controller: estoqueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Estoque'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomeController.text.isNotEmpty &&
                  precoController.text.isNotEmpty &&
                  estoqueController.text.isNotEmpty) {
                int estoque = int.tryParse(estoqueController.text) ?? 0;
                await _produtoRepository.adicionarProduto({
                  'lojistaId': widget.lojistaId,
                  'nome': nomeController.text,
                  'descricao': descricaoController.text,
                  'preco': double.tryParse(precoController.text) ?? 0,
                  'estoque': estoque,
                  'ativo': estoque > 0,
                });
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
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
        onPressed: () => _abrirDialogAdicionarProduto(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Gerencie seus produtos: edite estoque, adicione informações e controle disponibilidade.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_bag, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                Text(
                  "R\$ ${produto.preco.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  produto.estoque > 0 ? "Disponível" : "Indisponível",
                  style: TextStyle(
                    color: produto.estoque > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => _atualizarEstoque(produto, -1),
                  ),
                  Text(
                    produto.estoque.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.green,
                    ),
                    onPressed: () => _atualizarEstoque(produto, 1),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _excluirProduto(produto.id, produto.nome),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
