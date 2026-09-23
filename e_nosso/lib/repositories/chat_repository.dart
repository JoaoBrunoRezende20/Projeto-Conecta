import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Inicia ou atualiza a conversa raiz para um pedido.
  Future<void> iniciarConversa({
    required String pedidoId,
    required String clienteId,
    required String parceiroId,
    required String nomeCliente,
    required String nomeParceiro,
  }) async {
    try {
      final docRef = _firestore.collection('conversas').doc(pedidoId);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'pedidoId': pedidoId,
          'participantes': [clienteId, parceiroId],
          'nomeCliente': nomeCliente,
          'nomeParceiro': nomeParceiro,
          'ultimaMensagem': 'Chat iniciado',
          'ultimaAtualizacao': FieldValue.serverTimestamp(),
          'mensagensNaoLidas': {clienteId: 0, parceiroId: 0},
        });
      }
    } catch (e) {
      debugPrint('Erro ao iniciar conversa: $e');
    }
  }

  /// Envia uma nova mensagem na conversa do pedido
  Future<void> enviarMensagem({
    required String pedidoId,
    required String remetenteId,
    required String texto,
  }) async {
    try {
      final conversaRef = _firestore.collection('conversas').doc(pedidoId);
      final doc = await conversaRef.get();
      String outroId = '';
      if (doc.exists) {
        List p = doc.data()?['participantes'] ?? [];
        outroId = p.firstWhere((id) => id != remetenteId, orElse: () => '');
      }

      // Adiciona a mensagem na subcolecao 'mensagens'
      await conversaRef.collection('mensagens').add({
        'remetenteId': remetenteId,
        'texto': texto,
        'data': FieldValue.serverTimestamp(),
      });

      Map<String, dynamic> updates = {
        'ultimaMensagem': texto,
        'ultimaAtualizacao': FieldValue.serverTimestamp(),
      };

      if (outroId.isNotEmpty) {
        updates['mensagensNaoLidas.$outroId'] = FieldValue.increment(1);
      }

      // Atualiza os dados da conversa raiz
      await conversaRef.update(updates);

      // Tambem atualiza o pedido para refletir notificacoes pendentes
      if (outroId.isNotEmpty) {
        await _firestore
            .collection('pedidos')
            .doc(pedidoId)
            .update({'mensagensNaoLidas.$outroId': FieldValue.increment(1)})
            .catchError((_) => null);
      }
    } catch (e) {
      debugPrint('Erro ao enviar mensagem: $e');
    }
  }

  /// Marca a conversa como lida para um determinado usuario
  Future<void> marcarComoLido(String pedidoId, String usuarioLogadoId) async {
    try {
      await _firestore
          .collection('conversas')
          .doc(pedidoId)
          .update({'mensagensNaoLidas.$usuarioLogadoId': 0})
          .catchError((_) => null);

      await _firestore
          .collection('pedidos')
          .doc(pedidoId)
          .update({'mensagensNaoLidas.$usuarioLogadoId': 0})
          .catchError((_) => null);
    } catch (e) {
      debugPrint('Erro ao marcar como lido: $e');
    }
  }

  /// Retorna o stream de mensagens ordenadas por data
  Stream<QuerySnapshot> getMensagens(String pedidoId) {
    return _firestore
        .collection('conversas')
        .doc(pedidoId)
        .collection('mensagens')
        .orderBy('data', descending: true)
        .snapshots();
  }

  /// Opcional: Retorna as conversas ativas de um usuario (para futura lista de chats)
  Stream<QuerySnapshot> getConversasAtivas(String usuarioId) {
    return _firestore
        .collection('conversas')
        .where('participantes', arrayContains: usuarioId)
        .orderBy('ultimaAtualizacao', descending: true)
        .snapshots();
  }
}
