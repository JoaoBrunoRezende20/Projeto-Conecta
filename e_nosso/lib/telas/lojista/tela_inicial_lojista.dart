import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/widgets/botao_notificacao.dart';
import 'package:e_nosso/widgets/menu_lateral.dart';
import '../../repositories/produto_repository.dart';
import '../../repositories/pedido_repository.dart';


// --- CLASSE PRODUTO ---
class Produto {
  final String id;
  final String nome;
  final String descricao;
  final String caracteristicas;
  final double preco;
  final int estoque;
  bool ativo;

  Produto({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.caracteristicas,
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
      caracteristicas: data['caracteristicas'] ?? '',
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
  final ProdutoRepository _produtoRepository = ProdutoRepository();
  final PedidoRepository _pedidoRepository = PedidoRepository();

  
  // Controle de Abas: 0 (Produtos), 1 (Pedidos), 2 (Serviços)
  int _indiceAbaAtual = 0; 

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // --- LÓGICA DOS PRODUTOS ---
  void _abrirDialogAdicionarProduto(BuildContext context) {
    final nomeController = TextEditingController();
    final estoqueController = TextEditingController();
    final precoController = TextEditingController();
    final descricaoController = TextEditingController();
    final caracteristicasController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Adicionar Produto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome do Produto')),
              TextField(controller: descricaoController, decoration: const InputDecoration(labelText: 'Descrição')),
              TextField(controller: caracteristicasController, decoration: const InputDecoration(labelText: 'Características (ex: Sabor, Tamanho)')),
              TextField(controller: precoController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Preço (R\$)')),
              TextField(controller: estoqueController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Estoque')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nomeController.text.isNotEmpty && precoController.text.isNotEmpty && estoqueController.text.isNotEmpty) {
                int estoque = int.tryParse(estoqueController.text) ?? 0;
                await _produtoRepository.adicionarProduto({
                  'lojistaId': lojistaId,
                  'nome': nomeController.text,
                  'descricao': descricaoController.text,
                  'caracteristicas': caracteristicasController.text,
                  'preco': double.tryParse(precoController.text) ?? 0,
                  'estoque': estoque,
                  'ativo': estoque > 0,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _abrirDialogEditarProduto(BuildContext context, Produto produto) {
    final nomeController = TextEditingController(text: produto.nome);
    final descricaoController = TextEditingController(text: produto.descricao);
    final caracteristicasController = TextEditingController(text: produto.caracteristicas);
    final precoController = TextEditingController(text: produto.preco.toString());
    final estoqueController = TextEditingController(text: produto.estoque.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Produto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome do Produto')),
              TextField(controller: descricaoController, decoration: const InputDecoration(labelText: 'Descrição')),
              TextField(controller: caracteristicasController, decoration: const InputDecoration(labelText: 'Características (ex: Sabor, Tamanho)')),
              TextField(controller: precoController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Preço (R\$)')),
              TextField(controller: estoqueController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Estoque')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nomeController.text.isNotEmpty && precoController.text.isNotEmpty && estoqueController.text.isNotEmpty) {
                int estoque = int.tryParse(estoqueController.text) ?? 0;
                await _produtoRepository.atualizarProduto(produto.id, {
                  'nome': nomeController.text,
                  'descricao': descricaoController.text,
                  'caracteristicas': caracteristicasController.text,
                  'preco': double.tryParse(precoController.text) ?? 0,
                  'estoque': estoque,
                  'ativo': estoque > 0,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                }
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
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

  Future<void> _atualizarStatusPedido(String pedidoId, String novoStatus) async {
    await _pedidoRepository.atualizarStatusPedido(pedidoId, novoStatus);
  }

  // --- TRAVA DE ACESSO PARCIAL (StreamBuilder Principal) ---
@override
  Widget build(BuildContext context) {
    if (lojistaId == null) return const Scaffold(body: Center(child: Text("Erro de ID")));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('lojistas').doc(lojistaId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final dadosLojista = snapshot.data!.data() as Map<String, dynamic>?;
        if (dadosLojista == null) return const Scaffold(body: Center(child: Text("Cadastro não encontrado.")));

        final statusCadastro = dadosLojista['statusCadastro'] ?? 'pendente';
        final motivosRejeicao = dadosLojista['motivosRejeicao'] ?? '';

        if (statusCadastro == 'pendente') {
          return _buildTelaBloqueio(
            titulo: "Cadastro em Análise",
            // Texto exato exigido no Critério de Aceite:
            mensagem: "Sua conta está em análise. Aguarde a aprovação do Administrador.",
            icone: Icons.hourglass_top,
            cor: Colors.orange,
            mostrarBotaoReenvio: true, // Ativa o botão opcional
          );
        }

        if (statusCadastro == 'rejeitado') {
          return _buildTelaBloqueio(
            titulo: "Cadastro Não Aprovado",
            mensagem: "Infelizmente seu cadastro não foi aprovado neste momento.\n\nMotivo:\n$motivosRejeicao\n\nPor favor, entre em contato com o suporte.",
            icone: Icons.error_outline,
            cor: Colors.red,
            mostrarBotaoReenvio: false,
          );
        }

        // Se Aprovado, mostra o App Completo
        return _buildTelaAprovada();
      },
    );
  }

  // Interface de Validação Atualizada
  Widget _buildTelaBloqueio({
    required String titulo, 
    required String mensagem, 
    required IconData icone, 
    required Color cor,
    bool mostrarBotaoReenvio = false, // Novo parâmetro para o Critério Opcional
  }) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.black), onPressed: _signOut)]),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icone, size: 80, color: cor),
            const SizedBox(height: 24),
            Text(titulo, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cor), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(mensagem, style: const TextStyle(fontSize: 16, color: Colors.black54, height: 1.5), textAlign: TextAlign.center),
            
            // Requisito Opcional: Botão de Reenvio de Confirmação
            if (mostrarBotaoReenvio) ...[
              const SizedBox(height: 40),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.currentUser?.sendEmailVerification();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('E-mail de verificação reenviado com sucesso! Verifique a sua caixa de entrada e spam.'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao reenviar: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.mark_email_read),
                label: const Text('Reenviar E-mail de Confirmação'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cor,
                  side: BorderSide(color: cor),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
  // --- O PAINEL DE TRABALHO COMPLETO (COM 3 ABAS) ---
  Widget _buildTelaAprovada() {
    String tituloApp = 'Meus Produtos';
    if (_indiceAbaAtual == 1) tituloApp = 'Pedidos Recebidos';

    return Scaffold(
      backgroundColor: Colors.white,

      // --- CONFIGURAÇÃO DO MENU LATERAL ---
      drawer: MenuLateral(
        nomeUsuario:
            FirebaseAuth.instance.currentUser?.displayName ?? 'Lojista',
        urlFotoPerfil: FirebaseAuth.instance.currentUser?.photoURL,
        colecaoUsuario: 'lojistas',
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
          tituloApp,
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.black), onPressed: _signOut),
          BotaoNotificacao(colecaoUsuario: 'lojistas'),
          const SizedBox(width: 10),
        ],
      ),
      floatingActionButton: _indiceAbaAtual == 0
          ? FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: () => _abrirDialogAdicionarProduto(context),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      
      // Alternância de Abas
      body: _indiceAbaAtual == 0 
          ? _buildAbaProdutos() 
          : _buildAbaPedidos(),

      // Barra Inferior
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _indiceAbaAtual,
        onTap: (index) => setState(() => _indiceAbaAtual = index),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Produtos'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Pedidos'),
        ],
      ),
    );
  }

  // ABA 1: PRODUTOS
  Widget _buildAbaProdutos() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Gerencie seus produtos: edite estoque, adicione informações e controle disponibilidade.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _produtoRepository.getProdutosPorLojista(lojistaId!),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final produtos = snapshot.data!.docs.map((doc) => Produto.fromFirestore(doc)).toList();
        if (produtos.isEmpty) return const Center(child: Text("Nenhum produto cadastrado.", style: TextStyle(color: Colors.grey)));
        return ListView.builder(itemCount: produtos.length, itemBuilder: (_, i) => _buildProductTile(produtos[i]));
      },
    );
  }

  Widget _buildProductTile(Produto produto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.shopping_bag, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(produto.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text("R\$ ${produto.preco.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(produto.estoque > 0 ? "Disponível" : "Indisponível", style: TextStyle(color: produto.estoque > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => _atualizarEstoque(produto, -1)),
                  Text(produto.estoque.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green), onPressed: () => _atualizarEstoque(produto, 1)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _abrirDialogEditarProduto(context, produto)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _excluirProduto(produto.id, produto.nome)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAbaPedidos() {
    return StreamBuilder<QuerySnapshot>(
      stream: _pedidoRepository.getPedidosPorLojista(lojistaId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Erro: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final allDocs = snapshot.data!.docs.toList();
        final docs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status']?.toString().toLowerCase() ?? 'pendente';
          return status != 'concluido' && status != 'cancelado' && status != 'rejeitado';
        }).toList();
        
        try {
          docs.sort((a, b) {
            final mapA = a.data() as Map<String, dynamic>?;
            final mapB = b.data() as Map<String, dynamic>?;
            
            final dataA = mapA?['dataCriacao'];
            final dataB = mapB?['dataCriacao'];

            final Timestamp? tA = dataA is Timestamp ? dataA : null;
            final Timestamp? tB = dataB is Timestamp ? dataB : null;

            if (tA == null && tB == null) return 0;
            if (tA == null) return 1;
            if (tB == null) return -1;
            
            return tB.compareTo(tA);
          });
        } catch (e) {
          debugPrint("Erro ao ordenar pedidos: $e");
        }

        if (docs.isEmpty) return const Center(child: Text("Você ainda não recebeu nenhum pedido.", style: TextStyle(color: Colors.grey, fontSize: 16)));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            return _buildCardPedido(doc.data() as Map<String, dynamic>, doc.id);
          },
        );
      },
    );
  }

  String _formatarData(Timestamp? timestamp) {
    if (timestamp == null) return "00/00/0000";
    final data = timestamp.toDate();
    return "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}";
  }

  Widget _buildCardPedido(Map<String, dynamic> pedido, String pedidoId) {
    final dadosCliente = pedido['dadosCliente'] ?? {};
    final status = pedido['status']?.toString().toLowerCase() ?? 'pendente';
    final valorTotal = (pedido['valorTotal'] ?? 0.0).toDouble();
    final dataCriacao = pedido['dataCriacao'] as Timestamp?;
    
    String pagamentoStr = "Crédito";
    if (pedido['pagamento'] != null && pedido['pagamento']['metodo'] != null) {
      pagamentoStr = pedido['pagamento']['metodo'];
    } else if (pedido['pagamento'] is String) {
      pagamentoStr = pedido['pagamento'];
    }

    String entregaStr = "Entrega em casa";
    if (pedido['dadosEntrega'] != null && pedido['dadosEntrega']['tipoEntrega'] != null) {
      final tipo = pedido['dadosEntrega']['tipoEntrega'];
      final endereco = pedido['dadosEntrega']['endereco'];
      if (tipo == 'Entrega' && endereco != null && endereco.toString().isNotEmpty) {
        entregaStr = "Entrega: $endereco";
      } else {
        entregaStr = tipo;
      }
    }

    // Extrair Itens
    List<Map<String, dynamic>> itensList = [];
    if (pedido['itens'] is Map) {
      (pedido['itens'] as Map).forEach((key, val) {
        itensList.add({
          'nome': val['nome'] ?? 'Produto',
          'quantidade': val['quantidade'] ?? 1,
        });
      });
    } else if (pedido['itens'] is List) {
      for (var item in (pedido['itens'] as List)) {
        itensList.add({
          'nome': item['nome'] ?? 'Serviço',
          'quantidade': item['quantidade'] ?? 1,
        });
      }
    }

    if (itensList.isEmpty) {
      itensList.add({'nome': 'Pedido', 'quantidade': 1});
    }

    final nomeCliente = dadosCliente['nome'] ?? 'Cliente';

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5), // Fundo cinza claro
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinhado à esquerda
        children: [
          Text(
            "$nomeCliente**",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coluna da Esquerda (Itens)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: itensList.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['nome'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            "${item['quantidade']} Unidade${item['quantidade'] > 1 ? 's' : ''}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(width: 15),

              // Coluna da Direita (Valores e Infos)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "R\$ ${valorTotal.toStringAsFixed(2).replaceAll('.', ',')}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Pagamento no $pagamentoStr",
                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entregaStr,
                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatarData(dataCriacao),
                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          if (status == 'pendente') ...[
            const Center(
              child: Text(
                "Produto disponível no estoque!",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _atualizarStatusPedido(pedidoId, 'aceito'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Botão preto da imagem
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text(
                  "Confirmar envio",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (status == 'aceito') ...[
            const Center(
              child: Text(
                "Envio Confirmado!",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _atualizarStatusPedido(pedidoId, 'concluido'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text(
                  "Marcar como Entregue",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          
          // BOTÃO CHAT
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E8E8E), // Cinza botão
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: const Text(
                "Entrar em chat com o cliente",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          if (status == 'pendente') ...[
             const SizedBox(height: 10),
             SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _atualizarStatusPedido(pedidoId, 'rejeitado'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  "Recusar Pedido",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

}