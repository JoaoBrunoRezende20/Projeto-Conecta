import 'package:cloud_firestore/cloud_firestore.dart';

class ProdutoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getProdutosPorLojista(String lojistaId) {
    return _firestore
        .collection('produtos')
        .where('lojistaId', isEqualTo: lojistaId)
        .snapshots();
  }

  Future<void> adicionarProduto(Map<String, dynamic> dados) async {
    await _firestore.collection('produtos').add(dados);
  }

  Future<void> atualizarEstoque(String produtoId, int novoEstoque) async {
    await _firestore.collection('produtos').doc(produtoId).update({
      'estoque': novoEstoque,
      'ativo': novoEstoque > 0,
    });
  }

  Future<void> atualizarProduto(String produtoId, Map<String, dynamic> dados) async {
    await _firestore.collection('produtos').doc(produtoId).update(dados);
  }

  Future<void> deletarProduto(String produtoId) async {
    await _firestore.collection('produtos').doc(produtoId).delete();
  }

  // Validação mantida sem bloqueio de estoque
  Future<void> validarEstoqueItens(Map<String, dynamic> itens) async {
    // Compras liberadas sem trava de estoque (pedido das clientes)
  }

  // Atualização opcional de produto sem trava por concorrência
  Future<void> reduzirEstoqueProduto(String produtoId, int quantidade) async {
    // Não lança exceção e não bloqueia pedidos de clientes
  }

  // --- CENÁRIO C: Estorno de estoque (cancelamento/recusa) ---
  // Devolve a quantidade exata ao estoque de forma atômica.
  Future<void> devolverEstoqueProduto(String produtoId, int quantidade) async {
    final docRef = _firestore.collection('produtos').doc(produtoId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final int currentEstoque = (data['estoque'] ?? 0) as int;
      final int novoEstoque = currentEstoque + quantidade;

      transaction.update(docRef, {
        'estoque': novoEstoque,
        'ativo': novoEstoque > 0,
      });
    });
  }

}
