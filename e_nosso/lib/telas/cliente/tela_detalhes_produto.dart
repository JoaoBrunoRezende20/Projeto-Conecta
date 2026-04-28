import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tela_produtos_disponiveis.dart';
import '../../utils/carrinho_util.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Este widget é Stateful porque precisamos que a quantidade mude na tela
class TelaDetalhesProduto extends StatefulWidget {
  final Map<String, dynamic> produto; // Dados vindo do Firebase

  const TelaDetalhesProduto({super.key, required this.produto});

  @override
  State<TelaDetalhesProduto> createState() => _TelaDetalhesProdutoState();
}

class _TelaDetalhesProdutoState extends State<TelaDetalhesProduto> {
  int quantidade = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.menu, color: Colors.black),
        title: const Text(
          "Sabor da roça", // Nome da Loja
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Ícone de voltar circular à direita (como no Figma)
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 18,
                ),
                padding: const EdgeInsets.only(
                  left: 6,
                ), // Ajuste para centralizar
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
            // --- CARD CENTRAL PRINCIPAL (CINZA) ---
            // ==========================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, // Fundo branco
                border: Border.all(color: Colors.grey.shade300), // Borda cinza
                borderRadius: BorderRadius.circular(
                  25,
                ), // Bordas bem arredondadas
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
                          color: Colors.grey[200], // Cinza do mockup
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: widget.produto['imagemUrl'] != null
                            ? Image.network(
                                widget.produto['imagemUrl'],
                                fit: BoxFit.cover,
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
                              ),
                      ),
                      const SizedBox(width: 20),
                      // Infos do Produto
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.produto['nome'] ?? "Pão de queijo",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Descrição da composição do produto",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 25),
                            Text(
                              "R\$ ${widget.produto['preco'] ?? '0,00'} (*Preço)",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
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
                              onPressed: () => setState(
                                () => quantidade > 1 ? quantidade-- : null,
                              ),
                              icon: const Icon(Icons.remove, size: 18),
                            ),
                            Text(
                              "$quantidade",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => quantidade++),
                              icon: const Icon(Icons.add, size: 18),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Botão Adicionar à sacola
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _adicionarNaSacola();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.grey[300], // Cinza do mockup
                            foregroundColor: Colors.black, // Texto preto
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          child: const Text(
                            "Adicionar à sacola",
                            style: TextStyle(
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
                                child: semelhandoData['imagemUrl'] != null
                                    ? Image.network(semelhandoData['imagemUrl'], fit: BoxFit.cover)
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
      ),
    );
  }

  void _adicionarNaSacola() {
    final user = FirebaseAuth.instance.currentUser;
    final isVisitor = user == null || user.isAnonymous;

    if (isVisitor) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Autenticação necessária"),
          content: const Text("Por favor, faça login ou crie uma conta para adicionar produtos ao carrinho."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    final String? id = widget.produto['id'];
    if (id == null) return;

    setState(() {
      if (carrinhoGlobal.containsKey(id)) {
        carrinhoGlobal[id]!['quantidade'] += quantidade;
      } else {
        carrinhoGlobal[id] = {
          'nome': widget.produto['nome'],
          'preco': widget.produto['preco'],
          'quantidade': quantidade,
        };
      }
    });

    CarrinhoUtil.salvarCarrinho(carrinhoGlobal, lojaIdDoCarrinho);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Adicionado: $quantidade x ${widget.produto['nome'] ?? 'Produto'}"),
        backgroundColor: Colors.green,
      ),
    );
  }
}
