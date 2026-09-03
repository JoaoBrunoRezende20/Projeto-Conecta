import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/usuario_util.dart';
import 'tela_detalhes_prestador.dart';

class TelaDetalhesServico extends StatefulWidget {
  final Map<String, dynamic> prestador; // Dados do prestador e seus serviços

  const TelaDetalhesServico({super.key, required this.prestador});

  @override
  State<TelaDetalhesServico> createState() => _TelaDetalhesServicoState();
}

class _TelaDetalhesServicoState extends State<TelaDetalhesServico> {
  DateTime? dataSelecionada;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TelaDetalhesPrestador(
                  prestadorId: widget.prestador['prestadorId'] ?? "",
                ),
              ),
            );
          },
        ),
        title: Text(
          widget.prestador['nome'] ?? "Prestador de Serviço",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 18,
                ),
                padding: const EdgeInsets.only(left: 6),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Text(
            "DETALHAMENTO DOS SERVIÇOS",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 15),

          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                children: [
                  // Grid de Serviços (3 colunas)
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('servicos')
                          .where('prestadorId', isEqualTo: widget.prestador['prestadorId'])
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              "Nenhum serviço disponível.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        final servicosDocs = snapshot.data!.docs;

                        return GridView.builder(
                          itemCount: servicosDocs.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 20,
                                crossAxisSpacing: 15,
                                childAspectRatio: 0.7,
                              ),
                          itemBuilder: (context, index) {
                            final data = servicosDocs[index].data() as Map<String, dynamic>;
                            final nome = data['nome'] ?? 'Serviço';
                            final preco = data['preco'] ?? 0.0;
                            final imagem = (data['imagemUrl'] ?? data['imagemBase64']) as String?;

                            return Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: imagem != null && imagem.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(15),
                                            child: UsuarioUtil.buildImageWidget(
                                              imagem,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Center(
                                            child: Icon(
                                              Icons.image,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  nome,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "R\$ ${preco.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- BOTÕES DE AÇÃO NO RODAPÉ ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final telefone = widget.prestador['telefone'] ?? '';
                  if (telefone.isNotEmpty) {
                    final numWhats = telefone.replaceAll(RegExp(r'[^0-9]'), '');
                    final uri = Uri.parse("https://wa.me/55$numWhats");
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Telefone não informado pelo prestador."),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.phone),
                label: const Text("Entrar em Contato"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
