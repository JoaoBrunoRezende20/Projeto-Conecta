import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'telaNotificacoes.dart';

class BotaoNotificacao extends StatelessWidget {
  final String colecaoUsuario; // 'lojistas' ou 'prestadorServicos'

  const BotaoNotificacao({super.key, required this.colecaoUsuario});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      // Escuta APENAS as notificações não lidas para o contador
      stream: FirebaseFirestore.instance
          .collection(colecaoUsuario)
          .doc(user.uid)
          .collection('notificacoes')
          .where('lida', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
        }

        return IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TelaNotificacoes(colecaoUsuario: colecaoUsuario),
              ),
            );
          },
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            backgroundColor: Colors.red,
            child: const Icon(Icons.notifications_outlined, color: Colors.black),
          ),
        );
      },
    );
  }
}