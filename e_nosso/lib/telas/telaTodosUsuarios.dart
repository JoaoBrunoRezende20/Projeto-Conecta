import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TelaGerenciarUsuarios extends StatefulWidget {
  const TelaGerenciarUsuarios({super.key});

  @override
  State<TelaGerenciarUsuarios> createState() => _TelaGerenciarUsuariosState();
}

class _TelaGerenciarUsuariosState extends State<TelaGerenciarUsuarios> {
  final _currentUser = FirebaseAuth.instance.currentUser;

  // Função para Promover Usuário
  Future<void> _promoverUsuario(String uidAlvo, String nomeAlvo) async {
    // 1. Atualiza o tipo do usuário para 'admin'
    await FirebaseFirestore.instance.collection('usuarioComum').doc(uidAlvo).update({
      'tipo': 'admin',
    });

    // 2. Salva o Log Administrativo (Segurança)
    await FirebaseFirestore.instance.collection('logsAdministrativos').add({
      'dataHora': FieldValue.serverTimestamp(),
      'administradorUid': _currentUser?.uid,
      'administradorNome': 'Admin Atual (Você)', // Ideal buscar seu nome no banco antes
      'usuarioAfetadoUid': uidAlvo,
      'usuarioAfetadoNome': nomeAlvo,
      'acao': true, // True = Ação positiva/Aprovada
      'justificativa': 'Promovido a Administrador do Sistema.',
      'tipoAcao': 'PROMOCAO_ADMIN', // Tag extra para filtrar depois
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$nomeAlvo agora é um Administrador!')),
      );
    }
  }

  // Função para Rebaixar (Caso precise remover o admin de alguém)
  Future<void> _rebaixarUsuario(String uidAlvo, String nomeAlvo) async {
    await FirebaseFirestore.instance.collection('usuarioComum').doc(uidAlvo).update({
      'tipo': 'comum',
    });

    // Log do rebaixamento
    await FirebaseFirestore.instance.collection('logsAdministrativos').add({
      'dataHora': FieldValue.serverTimestamp(),
      'administradorUid': _currentUser?.uid,
      'administradorNome': 'Admin Atual',
      'usuarioAfetadoUid': uidAlvo,
      'usuarioAfetadoNome': nomeAlvo,
      'acao': false, // False = Ação restritiva
      'justificativa': 'Removido do cargo de Administrador.',
      'tipoAcao': 'REMOCAO_ADMIN',
    });
  }

  // Diálogo de Confirmação
  void _confirmarAcao(String uid, String nome, bool promover) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(promover ? 'Promover a Admin?' : 'Remover Admin?'),
        content: Text(promover
            ? 'Tem certeza que deseja dar acesso TOTAL ao sistema para $nome?'
            : 'Deseja transformar $nome em usuário comum novamente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: promover ? Colors.green : Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              if (promover) {
                _promoverUsuario(uid, nome);
              } else {
                _rebaixarUsuario(uid, nome);
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuários'),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Busca na coleção de usuarios comuns (onde estão os admins também, geralmente)
        stream: FirebaseFirestore.instance.collection('usuarioComum').orderBy('nome').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum usuário encontrado.'));
          }

          final usuarios = snapshot.data!.docs;

          return ListView.separated(
            itemCount: usuarios.length,
            separatorBuilder: (ctx, i) => const Divider(),
            itemBuilder: (context, index) {
              final dados = usuarios[index].data() as Map<String, dynamic>;
              final String uid = usuarios[index].id;
              final String nome = '${dados['nome'] ?? ''} ${dados['sobrenome'] ?? ''}';
              final String email = dados['email'] ?? 'Sem email';

              // Verifica o tipo atual
              final String tipo = dados['tipo'] ?? 'comum';
              final bool isAdmin = tipo == 'admin';

              // Não permite alterar o próprio usuário logado (pra não se bloquear)
              final bool isMe = uid == _currentUser?.uid;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isAdmin ? Colors.indigo : Colors.grey[300],
                  child: Icon(
                    isAdmin ? Icons.security : Icons.person,
                    color: isAdmin ? Colors.white : Colors.grey[600],
                  ),
                ),
                title: Text(nome, style: TextStyle(fontWeight: isAdmin ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text('$email\nTipo: ${tipo.toUpperCase()}'),
                isThreeLine: true,
                trailing: isMe
                    ? const Chip(label: Text('Você')) // Não pode alterar a si mesmo
                    : IconButton(
                  icon: Icon(
                    isAdmin ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isAdmin ? Colors.red : Colors.green,
                  ),
                  onPressed: () => _confirmarAcao(uid, nome, !isAdmin),
                  tooltip: isAdmin ? 'Rebaixar para Comum' : 'Promover a Admin',
                ),
              );
            },
          );
        },
      ),
    );
  }
}