import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/usuario_util.dart';

class TelaAdminConteudoPrestador extends StatefulWidget {
  final String uidPrestador;
  final String nomePrestador;

  const TelaAdminConteudoPrestador({super.key, required this.uidPrestador, required this.nomePrestador});

  @override
  State<TelaAdminConteudoPrestador> createState() => _TelaAdminConteudoPrestadorState();
}

class _TelaAdminConteudoPrestadorState extends State<TelaAdminConteudoPrestador> {

  // Função para remover uma imagem específica do Array 'portfolio'
  Future<void> _removerFotoPortfolio(String base64Image) async {
    try {
      await FirebaseFirestore.instance.collection('prestadorServicos').doc(widget.uidPrestador).update({
        'portfolio': FieldValue.arrayRemove([base64Image])
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imagem removida do portfólio.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Widget _buildImagemBase64(String base64String) {
    try {
      return Image.memory(UsuarioUtil.decodificarBase64(base64String), fit: BoxFit.cover);
    } catch (e) {
      return const Center(child: Icon(Icons.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Perfil de ${widget.nomePrestador}')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('prestadorServicos').doc(widget.uidPrestador).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final dados = snapshot.data!.data() as Map<String, dynamic>;
          final List portfolio = dados['portfolio'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Descrição do Serviço:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: Text(dados['descricaoServicos'] ?? 'Sem descrição'),
                ),

                const SizedBox(height: 24),
                const Text('Portfólio (Toque no X para apagar):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 10),

                if (portfolio.isEmpty) const Text('Nenhuma imagem no portfólio.'),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10
                  ),
                  itemCount: portfolio.length,
                  itemBuilder: (context, index) {
                    final imgString = portfolio[index];
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildImagemBase64(imgString),
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: InkWell(
                            onTap: () => _removerFotoPortfolio(imgString),
                            child: const CircleAvatar(
                              backgroundColor: Colors.red,
                              radius: 14,
                              child: Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        )
                      ],
                    );
                  },
                )
              ],
            ),
          );
        },
      ),
    );
  }
}