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


}
