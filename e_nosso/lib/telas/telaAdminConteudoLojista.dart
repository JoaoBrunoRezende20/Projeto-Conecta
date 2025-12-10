import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TelaAdminConteudoLojista extends StatelessWidget {
  final String lojistaId;
  final String nomeLojista;

  const TelaAdminConteudoLojista({super.key, required this.lojistaId, required this.nomeLojista});

  void _excluirProduto(BuildContext context, String idProduto, String nomeProduto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Produto?'),
        content: Text('Deseja apagar "$nomeProduto" do catálogo deste lojista?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('produtos').doc(idProduto).delete();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produto removido por violação.')));
              }
            },
            child: const Text('Excluir'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Produtos de $nomeLojista')),
      body: StreamBuilder<QuerySnapshot>(
        // Busca produtos onde o dono é este lojista
        stream: FirebaseFirestore.instance
            .collection('produtos')
            .where('lojistaId', isEqualTo: lojistaId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final produtos = snapshot.data!.docs;

          if (produtos.isEmpty) return const Center(child: Text('Este lojista não tem produtos cadastrados.'));

          return ListView.builder(
            itemCount: produtos.length,
            itemBuilder: (context, index) {
              final dados = produtos[index].data() as Map<String, dynamic>;
              final idProd = produtos[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: Text(dados['nome'] ?? 'Produto sem nome'),
                  subtitle: Text('R\$ ${dados['preco']?.toString() ?? '0.00'} | Qtd: ${dados['estoque']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _excluirProduto(context, idProd, dados['nome']),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}