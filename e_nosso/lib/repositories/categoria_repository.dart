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
}
