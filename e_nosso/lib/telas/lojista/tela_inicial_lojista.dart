import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/widgets/botao_notificacao.dart';
import 'package:e_nosso/widgets/menu_lateral.dart';
import '../../repositories/produto_repository.dart';
import '../../repositories/pedido_repository.dart';
import '../../repositories/categoria_repository.dart';

// --- CLASSE PRODUTO ---
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
  final ProdutoRepository _produtoRepository = ProdutoRepository();
  final PedidoRepository _pedidoRepository = PedidoRepository();
  final CategoriaRepository _categoriaRepository = CategoriaRepository();
  
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
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('E-mail de verificação reenviado com sucesso! Verifique a sua caixa de entrada e spam.'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
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
    if (_indiceAbaAtual == 2) tituloApp = 'Catálogo de Serviços';

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
          _indiceAbaAtual == 0 ? 'Meus Produtos' : 'Pedidos Recebidos',
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
          : _indiceAbaAtual == 1 
              ? _buildAbaPedidos() 
              : _buildAbaServicos(),

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
          BottomNavigationBarItem(icon: Icon(Icons.handyman), label: 'Serviços'),
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
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _excluirProduto(produto.id, produto.nome)),
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
        
        final docs = snapshot.data!.docs.toList();
        
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
          print("Erro ao ordenar pedidos: $e");
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

  Widget _buildCardPedido(Map<String, dynamic> pedido, String pedidoId) {
    final dadosCliente = pedido['dadosCliente'] ?? {};
    final itens = pedido['itens'] as Map<String, dynamic>? ?? {};
    final status = pedido['status'] ?? 'pendente';
    final valorTotal = pedido['valorTotal'] ?? 0.0;

    Color corStatus = Colors.orange;
    if (status == 'aceito') corStatus = Colors.blue;
    if (status == 'concluido') corStatus = Colors.green;
    if (status == 'cancelado') corStatus = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ExpansionTile(
        title: Text("Pedido de ${dadosCliente['nome'] ?? 'Cliente'}", style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: corStatus.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: corStatus)),
              child: Text(status.toUpperCase(), style: TextStyle(color: corStatus, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text("Total: R\$ ${valorTotal.toStringAsFixed(2)}", maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ITENS:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ...itens.entries.map((item) {
                  final itemData = item.value as Map<String, dynamic>;
                  return Text("${itemData['quantidade']}x ${itemData['nome']} (R\$ ${itemData['preco']})");
                }),
                const Divider(),
                if (status == 'pendente')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: Colors.red), onPressed: () => _atualizarStatusPedido(pedidoId, 'cancelado'), child: const Text("Recusar")),
                      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), onPressed: () => _atualizarStatusPedido(pedidoId, 'aceito'), child: const Text("Aceitar Pedido")),
                    ],
                  ),
                if (status == 'aceito')
                  SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () => _atualizarStatusPedido(pedidoId, 'concluido'), child: const Text("Marcar como Entregue"))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- NOVA ABA 3: CATÁLOGO DE SERVIÇOS ---
  Widget _buildAbaServicos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Precisa de manutenção na sua loja? Encontre profissionais qualificados aprovados pela plataforma.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // Consulta APENAS os prestadores que foram APROVADOS (status == true)
            stream: _categoriaRepository.getTodosPrestadoresAtivos(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final prestadores = snapshot.data!.docs;

              if (prestadores.isEmpty) {
                return const Center(
                  child: Text("Nenhum profissional disponível no momento.", style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: prestadores.length,
                itemBuilder: (context, index) {
                  final prestador = prestadores[index].data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.blue.shade50,
                        child: const Icon(Icons.engineering, color: Colors.blue),
                      ),
                      title: Text(
                        "${prestador['nome']} ${prestador['sobrenome']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(prestador['areaAtuacao'] ?? 'Serviços Gerais', style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text("Contato: ${prestador['telefone'] ?? 'Não informado'}", style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _mostrarDetalhesPrestador(prestador),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _mostrarDetalhesPrestador(Map<String, dynamic> prestador) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("${prestador['nome']} ${prestador['sobrenome']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text("Profissão: ${prestador['areaAtuacao']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
            const SizedBox(height: 16),
            const Text("Descrição dos Serviços:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            Text("${prestador['descricaoServicos'] ?? 'Não informada'}"),
            const SizedBox(height: 12),
            const Text("Telefone:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            Text("${prestador['telefone']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text("Preço Médio:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            Text("R\$ ${prestador['faixaPrecos']?.toString() ?? 'A combinar'}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ligue ou chame no WhatsApp usando o número acima.')),
              );
            },
            icon: const Icon(Icons.phone, color: Colors.white, size: 18),
            label: const Text('Contatar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}