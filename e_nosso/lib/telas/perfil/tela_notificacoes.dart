import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TelaNotificacoes extends StatelessWidget {
  final String colecaoUsuario; // 'lojistas' ou 'prestadorServicos'

  const TelaNotificacoes({super.key, required this.colecaoUsuario});

  String _formatarData(Timestamp? timestamp) {
    if (timestamp == null) return 'Data desconhecida';
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Erro: Não logado')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(colecaoUsuario)
            .doc(user.uid)
            .collection('notificacoes')
            .orderBy('data', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  const Text('Nenhuma notificação por enquanto.'),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool lida = data['lida'] ?? false;
              final bool isAprovado = data['tipo'] == 'aprovado';

              // LOGICA AUTOMÁTICA: Marca como lida se ainda não foi
              if (!lida) {
                doc.reference.update({'lida': true});
              }

              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: lida ? BorderSide.none : BorderSide(color: Colors.blue.shade200, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatarData(data['data']),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          if (!lida)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                              child: const Text('NOVA', style: TextStyle(color: Colors.white, fontSize: 10)),
                            )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['titulo'] ?? 'Sem título',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['mensagem'] ?? '',
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            isAprovado ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: isAprovado ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAprovado ? 'STATUS: APROVADO' : 'STATUS: REJEITADO',
                            style: TextStyle(
                              color: isAprovado ? Colors.green[700] : Colors.red[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}