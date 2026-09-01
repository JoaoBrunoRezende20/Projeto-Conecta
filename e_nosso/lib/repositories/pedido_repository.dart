import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_repository.dart';

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

  /// Envia uma notificação em tempo real para qualquer usuário (lojistas, prestadorServicos, usuarioComum)
  Future<void> enviarNotificacao({
    required String destinatarioId,
    required String colecaoDestinatario,
    required String titulo,
    required String mensagem,
    required String tipo,
    String? pedidoId,
  }) async {
    try {
      await _firestore
          .collection(colecaoDestinatario)
          .doc(destinatarioId)
          .collection('notificacoes')
          .add({
        'titulo': titulo,
        'mensagem': mensagem,
        'tipo': tipo,
        'pedidoId': pedidoId,
        'data': FieldValue.serverTimestamp(),
        'lida': false,
      });
    } catch (e) {
      // Evita que qualquer erro ao emitir a notificação quebre a transação do pedido
    }
  }

  Future<DocumentReference> criarPedido(Map<String, dynamic> dadosPedido) async {
    final docRef = await _firestore.collection('pedidos').add(dadosPedido);

    final String? lojistaId = dadosPedido['lojistaId'];
    final String? prestadorId = dadosPedido['prestadorId'];
    final String nomeCliente = dadosPedido['nomeCliente'] ??
        dadosPedido['dadosCliente']?['nome'] ??
        'Um cliente';

    if (lojistaId != null && lojistaId.isNotEmpty && lojistaId != 'desconhecido') {
      final double total = ((dadosPedido['valorTotal'] ?? 0) as num).toDouble();
      await enviarNotificacao(
        destinatarioId: lojistaId,
        colecaoDestinatario: 'lojistas',
        titulo: 'Novo Pedido Recebido!',
        mensagem: '$nomeCliente realizou um novo pedido no valor de R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}.',
        tipo: 'novo_pedido',
        pedidoId: docRef.id,
      );

      final String? clienteId = dadosPedido['clienteId'];
      final String nomeLoja = dadosPedido['dadosLojista']?['razaoSocial'] ?? 'Loja';
      if (clienteId != null) {
        await ChatRepository().iniciarConversa(
          pedidoId: docRef.id,
          clienteId: clienteId,
          parceiroId: lojistaId,
          nomeCliente: nomeCliente,
          nomeParceiro: nomeLoja,
        );
      }
    } else if (prestadorId != null && prestadorId.isNotEmpty) {
      await enviarNotificacao(
        destinatarioId: prestadorId,
        colecaoDestinatario: 'prestadorServicos',
        titulo: 'Nova Solicitação de Serviço!',
        mensagem: '$nomeCliente solicitou um agendamento/serviço com você.',
        tipo: 'solicitacao_servico',
        pedidoId: docRef.id,
      );

      final String? clienteId = dadosPedido['clienteId'];
      final String nomePrestador = dadosPedido['dadosPrestador']?['nome'] ?? 'Prestador';
      if (clienteId != null) {
        await ChatRepository().iniciarConversa(
          pedidoId: docRef.id,
          clienteId: clienteId,
          parceiroId: prestadorId,
          nomeCliente: nomeCliente,
          nomeParceiro: nomePrestador,
        );
      }
    }

    return docRef;
  }
}
