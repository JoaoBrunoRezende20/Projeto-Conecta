import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/usuario_util.dart';

class TelaDetalhesPrestador extends StatelessWidget {
  final String prestadorId;

  const TelaDetalhesPrestador({super.key, required this.prestadorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Detalhes do Prestador",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('prestadorServicos')
            .doc(prestadorId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Informações não encontradas."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final nomeCompleto = "${data['nome'] ?? ''} ${data['sobrenome'] ?? ''}".trim();
          final areaAtuacao = data['areaAtuacao'] ?? 'Prestador de Serviço';
          final email = data['email'] ?? 'Não informado';
          final telefone = data['telefone'] ?? 'Não informado';
          final descricao = data['descricaoServicos'] ?? data['descricao'] ?? 'O prestador ainda não adicionou uma descrição.';
          final disponibilidade = data['disponibilidadeAtendimento'] ?? 'Não informado';
          final urlFoto = data['urlFotoPerfil'] ?? data['fotoPerfil'] ?? data['fotoUrl'];
          
          List<dynamic> portfolioImagens = data['portfolio'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecalho com Avatar e Nome
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: urlFoto != null ? NetworkImage(urlFoto) : null,
                      child: urlFoto == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nomeCompleto.isEmpty ? 'Prestador' : nomeCompleto,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            areaAtuacao,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),
                
                // Sobre
                const Text(
                  "Sobre o prestador",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    descricao,
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                  ),
                ),
                const SizedBox(height: 35),

                // Horários de Atendimento
                const Text(
                  "Horários de Atendimento",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    disponibilidade,
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                  ),
                ),
                const SizedBox(height: 35),

                // Contato
                const Text(
                  "Informações de Contato",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.email_outlined, email),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: Divider(height: 1, color: Colors.black12),
                      ),
                      _buildInfoRow(Icons.phone_outlined, telefone),
                    ],
                  ),
                ),
                const SizedBox(height: 35),

                // Portfólio
                if (portfolioImagens.isNotEmpty) ...[
                  const Text(
                    "Portfólio / Trabalhos Anteriores",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: portfolioImagens.length,
                      itemBuilder: (context, index) {
                        final imageData = portfolioImagens[index] as String;
                        return GestureDetector(
                          onTap: () => _verImagemTelaCheia(context, imageData),
                          child: Container(
                            margin: const EdgeInsets.only(right: 15),
                            width: 130,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.grey[200],
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: _buildPortfolioImage(imageData),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ]
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 22),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioImage(String imageData) {
    return UsuarioUtil.buildImageWidget(imageData);
  }

  void _verImagemTelaCheia(BuildContext context, String imageData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                child: UsuarioUtil.buildImageWidget(imageData, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
