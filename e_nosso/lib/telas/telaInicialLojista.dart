import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'telaTipoUsuario.dart';

// Modelo de dados para organizar a informação de cada produto
class Produto {
  final String id;
  final String nome;
  final int estoque;
  bool ativo; // 'disponível' ou 'indisponível'

  Produto({
    required this.id,
    required this.nome,
    required this.estoque,
    required this.ativo,
  });

  // Construtor para criar um Produto a partir de um documento do Firestore
  factory Produto.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Produto(
      id: doc.id,
      nome: data['nome'] ?? 'Nome indisponível',
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

  // Função de Logout
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // Função para ATUALIZAR o status do produto no Firestore
  Future<void> _updateProdutoStatus(String produtoId, bool novoStatus) async {
    await FirebaseFirestore.instance
        .collection('produtos')
        .doc(produtoId)
        .update({'ativo': novoStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Controle de Produtos', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () { /* TODO: Abrir Drawer */ },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Controle nessa tela os produtos marcando-os como disponíveis ou indisponíveis. Após a seleção, os produtos ficarão marcados de acordo com a respectiva marcação.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _buildProductList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implementar lógica para adicionar novo produto
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProductList() {
    if (lojistaId == null) {
      return const Center(child: Text("Erro: Lojista não identificado."));
    }

    // StreamBuilder "ouve" as mudanças na coleção de produtos em tempo real
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('produtos')
          .where('lojistaId', isEqualTo: lojistaId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar produtos.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Você ainda não cadastrou nenhum produto.'));
        }

        final produtos = snapshot.data!.docs.map((doc) => Produto.fromFirestore(doc)).toList();

        return ListView.builder(
          itemCount: produtos.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return _buildProductTile(produtos[index]);
          },
        );
      },
    );
  }

  // Widget que constrói cada item da lista
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
          // Placeholder da imagem
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          // Nome e Checkboxes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(produto.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    Checkbox(
                      value: produto.ativo,
                      onChanged: (value) {
                        setState(() {
                          produto.ativo = true;
                        });
                        _updateProdutoStatus(produto.id, true);
                      },
                    ),
                    const Text('Disponível'),
                    Checkbox(
                      value: !produto.ativo,
                      onChanged: (value) {
                        setState(() {
                          produto.ativo = false;
                        });
                        _updateProdutoStatus(produto.id, false);
                      },
                    ),
                    const Text('Indisponível'),
                  ],
                ),
              ],
            ),
          ),
          // Estoque
          Column(
            children: [
              const Text('Unds'),
              Text(
                produto.estoque.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: produto.estoque == 0 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

