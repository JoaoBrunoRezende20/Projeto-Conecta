import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/widgets/botao_notificacao.dart';
import 'package:e_nosso/widgets/menu_lateral.dart';

// --- CLASSE PRODUTO (Mantida igual) ---
class Produto {
  final String id;
  final String nome;
  final String descricao;
  final double preco;
  final int estoque;
  bool ativo;

  Produto({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.estoque,
    required this.ativo,
  });

  factory Produto.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Produto(
      id: doc.id,
      nome: data['nome'] ?? 'Nome indisponível',
      descricao: data['descricao'] ?? '',
      preco: (data['preco'] ?? 0).toDouble(),
      estoque: data['estoque'] ?? 0,
      ativo: data['ativo'] ?? false,
    );
  }
}

class TelaInicialLojista extends StatefulWidget {
  const TelaInicialLojista({super.key});

  @override
  State<TelaInicialLojista> createState() => _TelaInicialLojistaState();
}

class _TelaInicialLojistaState extends State<TelaInicialLojista> {
  final String? lojistaId = FirebaseAuth.instance.currentUser?.uid;

  // NOVO: Controle de qual aba está selecionada na navegação inferior
  int _indiceAbaAtual = 0;

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // --- LÓGICA DOS PRODUTOS (Mantida igual) ---
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

                await FirebaseFirestore.instance.collection('produtos').add({
                  'lojistaId': lojistaId,
                  'nome': nomeController.text,
                  'descricao': descricaoController.text,
                  'preco': double.tryParse(precoController.text) ?? 0,
                  'estoque': estoque,
                  'ativo': estoque > 0,
                });

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

    if (confirmar == true) {
      FirebaseFirestore.instance.collection('produtos').doc(id).delete();
    }
  }

  Future<void> _atualizarEstoque(Produto produto, int delta) async {
    int novoEstoque = produto.estoque + delta;
    if (novoEstoque < 0) novoEstoque = 0;

    await FirebaseFirestore.instance
        .collection('produtos')
        .doc(produto.id)
        .update({'estoque': novoEstoque, 'ativo': novoEstoque > 0});
  }

  // NOVO: Lógica para mudar o status do pedido
  Future<void> _atualizarStatusPedido(
    String pedidoId,
    String novoStatus,
  ) async {
    await FirebaseFirestore.instance.collection('pedidos').doc(pedidoId).update(
      {'status': novoStatus},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // --- CONFIGURAÇÃO DO MENU LATERAL ---
      drawer: MenuLateral(
        nomeUsuario:
            FirebaseAuth.instance.currentUser?.displayName ?? 'Lojista',
        urlFotoPerfil: FirebaseAuth.instance.currentUser?.photoURL,
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        // --- BOTÃO DE GATILHO (Hambúrguer) ---
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),

        title: Text(
          _indiceAbaAtual == 0 ? 'Meus Produtos' : 'Pedidos Recebidos',
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _signOut,
          ),
          BotaoNotificacao(colecaoUsuario: 'lojistas'),
          const SizedBox(width: 10),
        ],
      ),

      // O botão de "Adicionar" só aparece na aba de Produtos
      floatingActionButton: _indiceAbaAtual == 0
          ? FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: () => _abrirDialogAdicionarProduto(context),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,

      // Alterna entre a Tela de Produtos e a Tela de Pedidos
      body: _indiceAbaAtual == 0 ? _buildAbaProdutos() : _buildAbaPedidos(),

      // Barra de navegação inferior
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAbaAtual,
        onTap: (index) {
          setState(() {
            _indiceAbaAtual = index;
          });
        },
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Produtos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
        ],
      ),
    );
  }

  // --- ABA 1: PRODUTOS ---
  Widget _buildAbaProdutos() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Gerencie seus produtos: edite estoque, adicione informações e controle disponibilidade automaticamente.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (lojistaId == null) {
      return const Center(child: Text("Erro: lojista não identificado"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('produtos')
          .where('lojistaId', isEqualTo: lojistaId)
          .snapshots(),
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
              "Nenhum produto cadastrado ainda.",
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
                ),
                Text(
                  produto.descricao,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
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
            children: [
              Row(
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

  // --- ABA 2: PEDIDOS RECEBIDOS ---
  Widget _buildAbaPedidos() {
    if (lojistaId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      // Puxa todos os pedidos que pertecem a esta loja
      stream: FirebaseFirestore.instance
          .collection('pedidos')
          .where('lojistaId', isEqualTo: lojistaId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Ordenamos os pedidos pelo mais recente usando a memória do Dart
        // (Evita erro de índice no Firestore)
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final dataA =
              (a.data() as Map<String, dynamic>)['dataCriacao'] as Timestamp?;
          final dataB =
              (b.data() as Map<String, dynamic>)['dataCriacao'] as Timestamp?;
          if (dataA == null || dataB == null) return 0;
          return dataB.compareTo(dataA); // Mais recente no topo
        });

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "Você ainda não recebeu nenhum pedido.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final pedido = doc.data() as Map<String, dynamic>;
            final pedidoId = doc.id;
            return _buildCardPedido(pedido, pedidoId);
          },
        );
      },
    );
  }

  Widget _buildCardPedido(Map<String, dynamic> pedido, String pedidoId) {
    // Extração segura dos dados
    final dadosCliente = pedido['dadosCliente'] ?? {};
    final dadosEntrega = pedido['dadosEntrega'] ?? {};
    final pagamento = pedido['pagamento'] ?? {};
    final itens = pedido['itens'] as Map<String, dynamic>? ?? {};
    final status = pedido['status'] ?? 'pendente';
    final valorTotal = pedido['valorTotal'] ?? 0.0;

    // Configuração de Cores por Status
    Color corStatus = Colors.orange;
    if (status == 'aceito') corStatus = Colors.blue;
    if (status == 'concluido') corStatus = Colors.green;
    if (status == 'cancelado') corStatus = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          "Pedido de ${dadosCliente['nome'] ?? 'Cliente'}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: corStatus.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: corStatus),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: corStatus,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text("Total: R\$ ${valorTotal.toStringAsFixed(2)}"),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- ITENS DO PEDIDO ---
                const Text(
                  "ITENS:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                ...itens.entries.map((item) {
                  final itemData = item.value as Map<String, dynamic>;
                  return Text(
                    "${itemData['quantidade']}x ${itemData['nome']} (R\$ ${itemData['preco']})",
                  );
                }),
                const Divider(),

                // --- ENDEREÇO ---
                const Text(
                  "ENTREGA:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  "${dadosEntrega['endereco']}, Nº ${dadosEntrega['numero']}",
                ),
                Text("Bairro: ${dadosEntrega['bairro']}"),
                Text("Contato: ${dadosCliente['telefone']}"),
                const Divider(),

                // --- PAGAMENTO ---
                const Text(
                  "PAGAMENTO:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Text("Método: ${pagamento['metodo']}"),
                if (pagamento['precisaTroco'] == true)
                  Text(
                    "LEVAR TROCO PARA: R\$ ${pagamento['trocoPara']}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                const SizedBox(height: 16),

                // --- BOTÕES DE AÇÃO ---
                if (status == 'pendente')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () =>
                            _atualizarStatusPedido(pedidoId, 'cancelado'),
                        child: const Text("Recusar"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: () =>
                            _atualizarStatusPedido(pedidoId, 'aceito'),
                        child: const Text("Aceitar Pedido"),
                      ),
                    ],
                  ),

                if (status == 'aceito')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () =>
                          _atualizarStatusPedido(pedidoId, 'concluido'),
                      child: const Text("Marcar como Entregue (Concluído)"),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
