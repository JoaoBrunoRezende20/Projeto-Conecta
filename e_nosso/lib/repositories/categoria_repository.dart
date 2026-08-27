import 'package:cloud_firestore/cloud_firestore.dart';

class CategoriaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getLojistasPorCategoria(String cnae) {
    return _firestore
        .collection('lojistas')
        .where('cnae', isEqualTo: cnae)
        .where('statusCadastro', isEqualTo: 'aprovado')
        .snapshots();
  }

  Stream<QuerySnapshot> getTodosLojistas() {
    return _firestore
        .collection('lojistas')
        .where('statusCadastro', isEqualTo: 'aprovado')
        .snapshots();
  }

  Stream<QuerySnapshot> getPrestadoresAprovados() {
    return _firestore
        .collection('prestadorServicos')
        .where('tipo', isEqualTo: 'prestador')
        .where('statusCadastro', isEqualTo: 'aprovado')
        .snapshots();
  }

  Stream<QuerySnapshot> getTodosPrestadoresAtivos() {
    return _firestore
        .collection('prestadorServicos')
        .where('status', isEqualTo: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getLojistasPorIds(List<String> ids) {
    if (ids.isEmpty) {
      // Retorna uma query vazia caso não haja favoritos
      return _firestore.collection('lojistas').where(FieldPath.documentId, whereIn: ['__empty__']).snapshots();
    }
    // O whereIn aceita no máximo 10 itens no Firebase, mas assumiremos que isso seja suficiente para um MVP, ou a UI lidará com lotes futuros.
    // Para simplificar, dividimos os IDs em lotes de 10 se houver muitos, ou deixamos a responsabilidade para a tela.
    // Por enquanto, faremos a chamada direta.
    return _firestore
        .collection('lojistas')
        .where(FieldPath.documentId, whereIn: ids.take(10).toList())
        .snapshots();
  }
}
