import 'package:cloud_firestore/cloud_firestore.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/usuario_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TelaNotificacoes extends StatelessWidget {
  final String colecaoUsuario; // 'lojistas' ou 'prestadorServicos'
  
  final AuthRepository _authRepository = AuthRepository();
  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  TelaNotificacoes({super.key, required this.colecaoUsuario});

  String _formatarData(Timestamp? timestamp) {
    if (timestamp == null) return 'Data desconhecida';
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final user = _authRepository.usuarioAtual;
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
        stream: _usuarioRepository.getNotificacoesStream(user.uid, colecaoUsuario),
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
              final String tipo = data['tipo'] ?? '';

              IconData icon;
              Color corStatus;
              String tag;

              switch (tipo) {
                case 'novo_pedido':
                  icon = Icons.shopping_bag_outlined;
                  corStatus = Colors.orange.shade800;
                  tag = 'NOVO PEDIDO';
                  break;
                case 'solicitacao_servico':
                  icon = Icons.handyman_outlined;
                  corStatus = Colors.blue.shade800;
                  tag = 'SOLICITAÇÃO DE SERVIÇO';
                  break;
                case 'pedido_aceito':
                case 'servico_aceito':
                  icon = Icons.check_circle_outline;
                  corStatus = Colors.green.shade800;
                  tag = 'CONFIRMADO';
                  break;
                case 'pedido_concluido':
                case 'servico_concluido':
                  icon = Icons.task_alt;
                  corStatus = Colors.teal.shade800;
                  tag = 'CONCLUÍDO';
                  break;
                case 'pedido_recusado':
                case 'servico_recusado':
                  icon = Icons.cancel_outlined;
                  corStatus = Colors.red.shade800;
                  tag = 'RECUSADO';
                  break;
                case 'aprovado':
                  icon = Icons.verified_user_outlined;
                  corStatus = Colors.green.shade800;
                  tag = 'CADASTRO APROVADO';
                  break;
                case 'rejeitado':
                  icon = Icons.gpp_bad_outlined;
                  corStatus = Colors.red.shade800;
                  tag = 'CADASTRO REJEITADO';
                  break;
                default:
                  icon = Icons.notifications_none;
                  corStatus = Colors.grey.shade700;
                  tag = 'AVISO';
              }

              // LOGICA AUTOMÁTICA: Marca como lida se ainda não foi
              if (!lida) {
                // OTIMIZAÇÃO: Usar addPostFrameCallback evita ciclos infinitos de leitura/gravação 
                // por tentar modificar o estado (Firebase) enquanto a UI ainda está sendo construída.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _usuarioRepository.marcarNotificacaoComoLida(user.uid, colecaoUsuario, doc.id);
                });
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
                            icon,
                            size: 16,
                            color: corStatus,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tag,
                            style: TextStyle(
                              color: corStatus,
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