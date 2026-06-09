import 'package:cloud_firestore/cloud_firestore.dart';

class PedidoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getPedidosPorLojista(String lojistaId) {
    return _firestore
        .collection('pedidos')
        .where('lojistaId', isEqualTo: lojistaId)
        .snapshots();
  }

  Stream<QuerySnapshot> getPedidosPorPrestador(String prestadorId, String status) {
    return _firestore
        .collection('pedidos')
        .where('prestadorId', isEqualTo: prestadorId)
        .where('status', isEqualTo: status)
        .snapshots();
  }
  
  Stream<QuerySnapshot> getPedidosPorPrestadorSemStatus(String prestadorId) {
    return _firestore
        .collection('pedidos')
        .where('prestadorId', isEqualTo: prestadorId)
        .snapshots();
  }

  Stream<QuerySnapshot> getPedidosPorCliente(String clienteId) {
    return _firestore
        .collection('pedidos')
        .where('clienteId', isEqualTo: clienteId)
        .snapshots();
  }

  Stream<QuerySnapshot> getServicosPendentesCliente(String clienteId) {
    return _firestore
        .collection('pedidos')
        .where('clienteId', isEqualTo: clienteId)
        .where('status', whereIn: ['Pendente', 'Confirmado'])
        .where('tipo', isEqualTo: 'servico')
        .snapshots();
  }

  Future<void> atualizarStatusPedido(String pedidoId, String novoStatus) async {
    await _firestore.collection('pedidos').doc(pedidoId).update({'status': novoStatus});
  }

  Future<void> criarPedido(Map<String, dynamic> dadosPedido) async {
    await _firestore.collection('pedidos').add(dadosPedido);
  }
}
