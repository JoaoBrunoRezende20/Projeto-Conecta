import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TelaLogsAdm extends StatefulWidget {
  const TelaLogsAdm({super.key});

  @override
  State<TelaLogsAdm> createState() => _TelaLogsAdmState();
}

class _TelaLogsAdmState extends State<TelaLogsAdm> {
  // --- ESTADO DOS FILTROS ---
  bool _filtroLojista = true;
  bool _filtroPrestador = true;
  bool _filtroOutros = true; // Admins, Promoções, Exclusões
  bool _filtroAprovado = true;
  bool _filtroRejeitado = true;

  String _formatarData(Timestamp? timestamp) {
    if (timestamp == null) return 'Data desconhecida';
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // --- POP-UP DE FILTROS ---
  void _mostrarFiltros() {
    showDialog(
      context: context,
      builder: (context) {
        bool tempLojista = _filtroLojista;
        bool tempPrestador = _filtroPrestador;
        bool tempOutros = _filtroOutros;
        bool tempAprovado = _filtroAprovado;
        bool tempRejeitado = _filtroRejeitado;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Center(child: Text('Filtrar Histórico')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      title: const Text('Lojistas'),
                      value: tempLojista,
                      onChanged: (v) =>
                          setStateDialog(() => tempLojista = v ?? true),
                    ),
                    CheckboxListTile(
                      title: const Text('Prestadores'),
                      value: tempPrestador,
                      onChanged: (v) =>
                          setStateDialog(() => tempPrestador = v ?? true),
                    ),
                    CheckboxListTile(
                      title: const Text('Admin / Sistema'),
                      value: tempOutros,
                      onChanged: (v) =>
                          setStateDialog(() => tempOutros = v ?? true),
                    ),
                    const Divider(),
                    CheckboxListTile(
                      title: const Text('Ações Positivas (Aprov/Promo)'),
                      value: tempAprovado,
                      activeColor: Colors.green,
                      onChanged: (v) =>
                          setStateDialog(() => tempAprovado = v ?? true),
                    ),
                    CheckboxListTile(
                      title: const Text('Ações Negativas (Rej/Ban)'),
                      value: tempRejeitado,
                      activeColor: Colors.red,
                      onChanged: (v) =>
                          setStateDialog(() => tempRejeitado = v ?? true),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Voltar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filtroLojista = tempLojista;
                      _filtroPrestador = tempPrestador;
                      _filtroOutros = tempOutros;
                      _filtroAprovado = tempAprovado;
                      _filtroRejeitado = tempRejeitado;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoria e Logs'),
        backgroundColor: const Color(0xFF424242),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.tune), onPressed: _mostrarFiltros),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('logsAdministrativos')
            .orderBy('dataHora', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final todosLogs = snapshot.data!.docs;

          // --- FILTRAGEM ---
          final logsFiltrados = todosLogs.where((doc) {
            final dados = doc.data() as Map<String, dynamic>;
            final bool acao = dados['acao'] ?? false;
            final String tipo =
                dados['tipoUsuario'] ??
                'outros'; // lojistas, prestadorServicos ou outros

            // Filtro de Status
            if (acao == true && !_filtroAprovado) return false;
            if (acao == false && !_filtroRejeitado) return false;

            // Filtro de Tipo
            if (tipo == 'lojistas' && !_filtroLojista) return false;
            if (tipo == 'prestadorServicos' && !_filtroPrestador) return false;
            if (tipo != 'lojistas' &&
                tipo != 'prestadorServicos' &&
                !_filtroOutros)
              return false;

            return true;
          }).toList();

          if (logsFiltrados.isEmpty) {
            return const Center(child: Text('Nenhum log encontrado.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: logsFiltrados.length,
            itemBuilder: (context, index) {
              final dados = logsFiltrados[index].data() as Map<String, dynamic>;

              final bool acaoPositiva = dados['acao'] ?? false;
              final String adminNome = dados['administradorNome'] ?? 'Admin';
              final String afetadoNome =
                  dados['usuarioAfetadoNome'] ?? 'Usuário';
              final String justificativa = dados['justificativa'] ?? '';
              final Timestamp? dataHora = dados['dataHora'];

              // Campo que define se foi Promoção, Rebaixamento, Cadastro, etc.
              final String? tipoAcao = dados['tipoAcao'];

              // --- LÓGICA VISUAL INTELIGENTE ---
              Color corFundo;
              Color corTexto;
              IconData icone;
              String textoStatus;

              if (tipoAcao == 'PROMOCAO_ADMIN') {
                // Caso: Virou Admin
                corFundo = Colors.indigo.shade100;
                corTexto = Colors.indigo.shade900;
                icone = Icons.security;
                textoStatus = 'NOVO ADMIN';
              } else if (tipoAcao == 'REBAIXAMENTO') {
                // Caso: Perdeu Admin
                corFundo = Colors.orange.shade100;
                corTexto = Colors.orange.shade900;
                icone = Icons.remove_moderator;
                textoStatus = 'REBAIXADO';
              } else if (tipoAcao == 'EXCLUSAO' ||
                  tipoAcao == 'EXCLUSAO_CONTA') {
                // Caso: Banido / Excluído
                corFundo = Colors.red.shade100;
                corTexto = Colors.red.shade900;
                icone = Icons.delete_forever;
                textoStatus = 'EXCLUÍDO';
              } else {
                // Caso Padrão: Validação de Cadastro (Aprovado/Rejeitado)
                if (acaoPositiva) {
                  corFundo = Colors.green.shade100;
                  corTexto = Colors.green.shade900;
                  icone = Icons.check_circle;
                  textoStatus = 'APROVADO';
                } else {
                  corFundo = Colors.red.shade100;
                  corTexto = Colors.red.shade900;
                  icone = Icons.cancel;
                  textoStatus = 'REJEITADO';
                }
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Linha Superior: Data e Badge de Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatarData(dataHora),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          // BADGE PERSONALIZADO
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: corFundo,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: corTexto.withOpacity(0.5),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(icone, size: 14, color: corTexto),
                                const SizedBox(width: 4),
                                Text(
                                  textoStatus,
                                  style: TextStyle(
                                    color: corTexto,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Admin: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: '$adminNome\n'),
                            const TextSpan(
                              text: 'Alvo: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: afetadoNome),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (justificativa.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detalhes:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                justificativa,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
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
