import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar a data

class TelaLogsAdm extends StatelessWidget {
  const TelaLogsAdm({super.key});

  // Função auxiliar para formatar o Timestamp do Firestore
  String _formatarData(Timestamp? timestamp) {
    if (timestamp == null) return 'Data desconhecida';
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoria e Logs'),
        backgroundColor: Colors.blueGrey[900], // Cor mais sóbria para Adm
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        // Ordena pelo log mais recente primeiro (descending: true)
        stream: FirebaseFirestore.instance
            .collection('logsAdministrativos')
            .orderBy('dataHora', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar logs.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('Nenhum registro de atividade encontrado.'),
                ],
              ),
            );
          }

          final logs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final dados = logs[index].data() as Map<String, dynamic>;

              // Extraindo dados com segurança
              final bool acaoAprovada = dados['acao'] ?? false; // true = Aprovado, false = Rejeitado
              final String adminNome = dados['administradorNome'] ?? 'Admin Desconhecido';
              final String afetadoNome = dados['usuarioAfetadoNome'] ?? 'Usuário';
              final String justificativa = dados['justificativa'] ?? 'Sem justificativa';
              final Timestamp? dataHora = dados['dataHora'];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- CABEÇALHO (Data e Status Visual) ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey[600]
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
                          // Chip visual de Status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: acaoAprovada ? Colors.green[100] : Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: acaoAprovada ? Colors.green : Colors.red,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  acaoAprovada ? Icons.check_circle : Icons.cancel,
                                  size: 14,
                                  color: acaoAprovada ? Colors.green[800] : Colors.red[800],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  acaoAprovada ? 'APROVADO' : 'REJEITADO',
                                  style: TextStyle(
                                    color: acaoAprovada ? Colors.green[900] : Colors.red[900],
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

                      // --- CORPO DO LOG ---
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black87, fontSize: 14),
                          children: [
                            const TextSpan(text: 'Admin: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: '$adminNome\n'),
                            const TextSpan(text: 'Alvo: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: '$afetadoNome'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // --- JUSTIFICATIVA (SE HOUVER) ---
                      if (justificativa.isNotEmpty && justificativa != 'Sem justificativa') ...[
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
                                'Justificativa:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                justificativa,
                                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      ],
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