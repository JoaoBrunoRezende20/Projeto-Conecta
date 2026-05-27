import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UsuarioRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Descobre a qual coleção o usuário pertence (Role)
  Future<String?> descobrirPerfilUsuario(String uid) async {
    try {
      // OTIMIZAÇÃO: Executa as 4 consultas simultaneamente (em paralelo)
      // Isso reduz o tempo de carregamento no login/abertura do app para 1/4 do tempo anterior.
      final resultados = await Future.wait([
        _firestore.collection('admins').doc(uid).get(),
        _firestore.collection('lojistas').doc(uid).get(),
        _firestore.collection('prestadorServicos').doc(uid).get(),
        _firestore.collection('usuarioComum').doc(uid).get(),
      ]);

      if (resultados[0].exists) return 'admins';
      if (resultados[1].exists) return 'lojistas';
      if (resultados[2].exists) return 'prestadorServicos';
      if (resultados[3].exists) return 'usuarioComum';

    } catch (e) {
      debugPrint('Erro ao descobrir perfil do usuário: $e');
    }
    return null;
  }

  /// Salva ou atualiza os dados de um usuário no Firestore
  Future<void> salvarDadosUsuario(String uid, String colecao, Map<String, dynamic> dados) async {
    await _firestore.collection(colecao).doc(uid).set(
      dados,
      SetOptions(merge: true), // Merge garante que não sobrescreva campos não passados
    );
  }

  /// Busca os dados do usuário de forma assíncrona (uma vez)
  Future<DocumentSnapshot> getUsuario(String uid, String colecao) async {
    return await _firestore.collection(colecao).doc(uid).get();
  }

  /// Retorna um Stream para ouvir as atualizações do perfil do usuário em tempo real
  Stream<DocumentSnapshot> getUsuarioStream(String uid, String colecao) {
    return _firestore.collection(colecao).doc(uid).snapshots();
  }

  /// Retorna um Stream para ouvir as notificações do usuário
  Stream<QuerySnapshot> getNotificacoesStream(String uid, String colecao) {
    return _firestore
        .collection(colecao)
        .doc(uid)
        .collection('notificacoes')
        .orderBy('data', descending: true)
        .snapshots();
  }

  /// Marca uma notificação como lida
  Future<void> marcarNotificacaoComoLida(String uid, String colecao, String idNotificacao) async {
    await _firestore
        .collection(colecao)
        .doc(uid)
        .collection('notificacoes')
        .doc(idNotificacao)
        .update({'lida': true});
  }
}
