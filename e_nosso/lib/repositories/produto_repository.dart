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

  // --- CENÁRIO A: Validação prévia de estoque ---
  // Lê o estoque atual de cada produto e lança uma exceção descritiva
  // caso algum item esteja com quantidade insuficiente.
  Future<void> validarEstoqueItens(Map<String, dynamic> itens) async {
    for (final entry in itens.entries) {
      final produtoId = entry.key;
      final itemData = entry.value as Map<String, dynamic>;
      final int quantidadeSolicitada = (itemData['quantidade'] as num).toInt();
      final String nomeProduto = itemData['nome']?.toString() ?? 'Produto';

      final doc = await _firestore.collection('produtos').doc(produtoId).get();

      if (!doc.exists) {
        throw Exception('O produto "$nomeProduto" não foi encontrado.');
      }

      final data = doc.data() as Map<String, dynamic>;
      final int estoqueAtual = (data['estoque'] ?? 0) as int;

      if (estoqueAtual < quantidadeSolicitada) {
        throw Exception(
          'Estoque insuficiente para "$nomeProduto".\n'
          'Disponível: $estoqueAtual | Solicitado: $quantidadeSolicitada.',
        );
      }
    }
  }

  // --- CENÁRIO B: Dedução atômica com validação dentro da Transaction ---
  // O Firestore garante isolamento serial: se dois clientes executam
  // simultaneamente, o segundo verá o estoque já zerado e terá a
  // transação abortada com exceção, evitando furo de estoque.
  Future<void> reduzirEstoqueProduto(String produtoId, int quantidade) async {
    final docRef = _firestore.collection('produtos').doc(produtoId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Produto não encontrado no banco de dados.');
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final int currentEstoque = (data['estoque'] ?? 0) as int;
      final String nomeProduto = data['nome']?.toString() ?? 'Produto';

      // Valida DENTRO da transaction — garante consistência mesmo em concorrência
      if (currentEstoque < quantidade) {
        throw Exception(
          'Estoque insuficiente para "$nomeProduto" (conflito de concorrência).\n'
          'Disponível: $currentEstoque | Solicitado: $quantidade.',
        );
      }

      final int novoEstoque = currentEstoque - quantidade;
      transaction.update(docRef, {
        'estoque': novoEstoque,
        'ativo': novoEstoque > 0,
      });
    });
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
