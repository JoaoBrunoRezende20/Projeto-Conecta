import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/usuario_util.dart';
import 'tela_cadastro_servico_prestador.dart';

class TelaGerenciarServicosPrestador extends StatefulWidget {
  const TelaGerenciarServicosPrestador({super.key});

  @override
  State<TelaGerenciarServicosPrestador> createState() =>
      _TelaGerenciarServicosPrestadorState();
}

class _TelaGerenciarServicosPrestadorState
    extends State<TelaGerenciarServicosPrestador> {
  final String? prestadorId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _excluirServico(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir serviço'),
        content: const Text('Tem certeza que deseja excluir este serviço?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await FirebaseFirestore.instance.collection('servicos').doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serviço excluído com sucesso!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (prestadorId == null) {
      return const Scaffold(
        body: Center(child: Text('Erro: Usuário não logado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Serviços'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('servicos')
            .where('prestadorId', isEqualTo: prestadorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nenhum serviço cadastrado.'),
            );
          }

          final servicosDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: servicosDocs.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final doc = servicosDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              final nome = data['nome'] ?? 'Sem nome';
              final preco = data['preco'] ?? 0.0;
              final imagemBase64 = data['imagemBase64'] as String?;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: ListTile(
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: imagemBase64 != null && imagemBase64.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: UsuarioUtil.buildImageWidget(
                              imagemBase64,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                  title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('R\$ ${preco.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TelaCadastroServicoPrestador(
                                servicoId: doc.id,
                                nomeAtual: nome,
                                precoAtual: preco is double ? preco : double.tryParse(preco.toString()) ?? 0.0,
                                imagemBase64Atual: imagemBase64,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _excluirServico(doc.id),
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
