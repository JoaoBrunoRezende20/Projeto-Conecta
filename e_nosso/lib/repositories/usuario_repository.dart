import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UsuarioRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Descobre a qual coleção o usuário pertence (Role)
  Future<String?> descobrirPerfilUsuario(String uid) async {
    try {
      // 1. Tenta encontrar o UID na coleção de Admins
      final adminDoc = await _firestore.collection('admins').doc(uid).get();
      if (adminDoc.exists) return 'admins';

      // 2. Tenta encontrar o UID na coleção de Lojistas
      final lojistaDoc = await _firestore.collection('lojistas').doc(uid).get();
      if (lojistaDoc.exists) return 'lojistas';

      // 3. Tenta encontrar o UID na coleção de Prestadores
      final prestadorDoc = await _firestore.collection('prestadorServicos').doc(uid).get();
      if (prestadorDoc.exists) return 'prestadorServicos';

      // 4. Tenta encontrar o UID na coleção de Clientes (Comum)
      final comumDoc = await _firestore.collection('usuarioComum').doc(uid).get();
      if (comumDoc.exists) return 'usuarioComum';

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
