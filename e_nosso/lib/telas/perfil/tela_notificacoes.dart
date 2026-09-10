import 'package:cloud_firestore/cloud_firestore.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/usuario_repository.dart';
import '../cliente/tela_avaliacao_servico.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TelaNotificacoes extends StatelessWidget {
  final String colecaoUsuario; // 'lojistas', 'prestadorServicos' ou 'usuarioComum'
  
  final AuthRepository _authRepository = AuthRepository();
  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  TelaNotificacoes({super.key, required this.colecaoUsuario});

  String _formatarData(Timestamp? timestamp) {
    if (timestamp == null) return 'Data desconhecida';
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  Future<void> _abrirAvaliacao(BuildContext context, Map<String, dynamic> notifData) async {
    final String? pedidoId = notifData['pedidoId'] as String?;
    if (pedidoId == null || pedidoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identificador do pedido não encontrado.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool dialogAberto = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Abrindo avaliação...'),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => dialogAberto = false);
    dialogAberto = true;

    try {
      final doc = await FirebaseFirestore.instance.collection('pedidos').doc(pedidoId).get();

      if (dialogAberto && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogAberto = false;
      }

      if (!doc.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pedido não encontrado.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final pedidoData = doc.data() ?? {};
      final bool avaliado = pedidoData['avaliado'] ?? false;
      if (avaliado) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este pedido já foi avaliado. Obrigado pelo seu feedback!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      final String? pId = pedidoData['prestadorId'] as String? ?? notifData['alvoId'] as String?;
      final String? lojistaId = pedidoData['lojistaId'] as String? ?? notifData['alvoId'] as String?;
      final bool isPrestador = (pId != null && pId.isNotEmpty) || (notifData['tipoAlvo'] == 'prestador');
      final String alvoId = isPrestador ? (pId ?? '') : (lojistaId ?? '');
      final String tipoAlvo = isPrestador ? 'prestador' : 'lojista';
      final String nomeAlvo = notifData['nomeAlvo'] ??
          pedidoData['dadosLojista']?['razaoSocial'] ??
          pedidoData['dadosPrestador']?['nome'] ??
          pedidoData['nomeLoja'] ??
          pedidoData['loja'] ??
          pedidoData['prestador'] ??
          (isPrestador ? 'Prestador' : 'Loja');

      if (alvoId.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Identificação do estabelecimento não encontrada para avaliação.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TelaAvaliacaoServico(
              pedidoId: pedidoId,
              prestadorId: alvoId,
              nomePrestador: nomeAlvo,
              tipoAlvo: tipoAlvo,
            ),
          ),
        );
      }
    } catch (e) {
      if (dialogAberto && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogAberto = false;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir avaliação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _usuarioRepository.marcarNotificacaoComoLida(user.uid, colecaoUsuario, doc.id);
                });
              }

              final bool isAvaliacao = (tipo == 'pedido_concluido' || tipo == 'servico_concluido') &&
                  data['pedidoId'] != null &&
                  (data['pedidoId'] as String).isNotEmpty;
              final String labelAvaliar = tipo == 'servico_concluido' ? 'Avaliar Prestador' : 'Avaliar Loja';

              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: lida ? BorderSide.none : BorderSide(color: Colors.blue.shade200, width: 1.5),
                ),
                child: InkWell(
                  onTap: isAvaliacao ? () => _abrirAvaliacao(context, data) : null,
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
                        ),
                        if (isAvaliacao) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _abrirAvaliacao(context, data),
                              icon: const Icon(Icons.star_rounded, size: 20),
                              label: Text(labelAvaliar),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B9467),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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