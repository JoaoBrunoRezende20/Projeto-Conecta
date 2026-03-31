/*import 'package:flutter/material.dart';

class Produto {
  final String nome;
  bool disponivel;
  int quantidade;

  Produto(this.nome, this.disponivel, this.quantidade);
}

class ControleProdutos extends StatefulWidget {
  @override
  _ControleProdutosState createState() => _ControleProdutosState();
}

class _ControleProdutosState extends State<ControleProdutos> {
  List<Produto> produtos = [
    Produto('Pão de Queijo', false, 0),
    Produto('Enroladinho de Salsicha', true, 100),
    Produto('Empada', true, 39),
    Produto('Coxinha', true, 100),
    Produto('Hambúrguer', true, 100),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Controle de Produtos'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controle nessa tela os produtos marcando-os como disponíveis ou indisponíveis. Após a seleção, os produtos ficarão marcados de acordo com a respectiva marcação.',
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
            SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: produtos.length,
                itemBuilder: (context, index) {
                  final produto = produtos[index];

                  Color getQuantidadeColor() {
                    if (produto.quantidade == 0) {
                      return Colors.red;
                    } else if (produto.quantidade < 50) {
                      return Colors.grey;
                    } else {
                      return Colors.green;
                    }
                  }

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.grey[200],
                    margin: EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  produto.nome,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: produto.disponivel,
                                            onChanged: (value) {
                                              setState(() {
                                                produto.disponivel = value!;
                                              });
                                            },
                                          ),
                                          Text('Disponível'),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: !produto.disponivel,
                                            onChanged: (value) {
                                              setState(() {
                                                produto.disponivel = !value!;
                                              });
                                            },
                                          ),
                                          Text('Indisponível'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                'Unds',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                              Text(
                                '${produto.quantidade}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: getQuantidadeColor(),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
import 'package:flutter/material.dart';

class Produto {
  final String nome;
  bool disponivel;
  int quantidade;

  Produto(this.nome, this.disponivel, this.quantidade);
}

class ControleProdutosLojista extends StatefulWidget {
  const ControleProdutosLojista({super.key});

  @override
  State<ControleProdutosLojista> createState() =>
      _ControleProdutosLojistaState();
}

class _ControleProdutosLojistaState extends State<ControleProdutosLojista> {
  // Lista inicial de produtos
  List<Produto> produtos = [
    Produto('Pão de Queijo', false, 0),
    Produto('Enroladinho de Salsicha', true, 100),
    Produto('Empada', true, 39),
    Produto('Coxinha', true, 100),
    Produto('Hambúrguer', true, 100),
  ];

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController quantidadeController = TextEditingController();

  void adicionarProduto() {
    if (nomeController.text.isNotEmpty &&
        quantidadeController.text.isNotEmpty) {
      setState(() {
        produtos.add(
          Produto(
            nomeController.text,
            true,
            int.tryParse(quantidadeController.text) ?? 0,
          ),
        );
      });
      nomeController.clear();
      quantidadeController.clear();
      Navigator.pop(context);
    }
  }

  void removerProduto(int index) {
    setState(() {
      produtos.removeAt(index);
    });
  }

  void abrirDialogAdicionar() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Adicionar Produto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome do Produto'),
            ),
            TextField(
              controller: quantidadeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade (Unds)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: adicionarProduto,
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Color getQuantidadeColor(int quantidade) {
    if (quantidade == 0) return Colors.red;
    if (quantidade < 50) return Colors.grey;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Produtos'),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: abrirDialogAdicionar,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gerencie seus produtos: adicione, altere estoque, marque como disponíveis ou remova.',
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: produtos.isEmpty
                  ? const Center(
                      child: Text(
                        'Você ainda não cadastrou nenhum produto.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: produtos.length,
                      itemBuilder: (context, index) {
                        final produto = produtos[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.grey[200],
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[400],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        produto.nome,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value: produto.disponivel,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      produto.disponivel =
                                                          value!;
                                                    });
                                                  },
                                                ),
                                                const Text('Disponível'),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value: !produto.disponivel,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      produto.disponivel =
                                                          !value!;
                                                    });
                                                  },
                                                ),
                                                const Text('Indisponível'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Text(
                                            'Estoque: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                if (produto.quantidade > 0) {
                                                  produto.quantidade--;
                                                }
                                              });
                                            },
                                          ),
                                          Text(
                                            '${produto.quantidade}',
                                            style: TextStyle(
                                              color: getQuantidadeColor(
                                                produto.quantidade,
                                              ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                produto.quantidade++;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => removerProduto(index),
                                    ),
                                    const Text(
                                      'Unds',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
