import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/widgets/menu_lateral.dart';
import '/widgets/botao_notificacao.dart';
import '../../utils/usuario_util.dart';

// --- Modelos de Dados (para organizar a informação) ---

// Guarda os dados do perfil do prestador
class PrestadorProfile {
  final String nome;
  final String areaAtuacao;

  PrestadorProfile({required this.nome, required this.areaAtuacao});
}

// --- A Tela ---

class TelaInicialPrestador extends StatefulWidget {
  const TelaInicialPrestador({super.key});

  @override
  State<TelaInicialPrestador> createState() => _TelaInicialPrestadorState();
}

class _TelaInicialPrestadorState extends State<TelaInicialPrestador> {

  // A função de Logout agora é muito mais simples.
  Future<void> _signOut() async {
    // Apenas avisa ao Firebase para deslogar.
    // O AuthWrapper no main.dart vai ouvir essa mudança e
    // automaticamente redirecionar para a TelaTipoUsuario.
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Erro de ID")));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('prestadorServicos').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const Scaffold(body: Center(child: Text("Cadastro não encontrado.")));

        final nomeFormatado = UsuarioUtil.getNomeCompleto(data, colecao: 'prestadorServicos');
        final areaAtuacao = data['areaAtuacao'] ?? "Profissão não definida";
        
        final prestador = PrestadorProfile(nome: nomeFormatado, areaAtuacao: areaAtuacao);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: const Text('Seu Perfil', style: TextStyle(color: Colors.black)),
            leading: Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.black),
                onPressed: _signOut,
              ),
              BotaoNotificacao(colecaoUsuario: 'prestadorServicos'),
              const SizedBox(width: 10),
            ],
          ),
          drawer: MenuLateral(
            nomeUsuario: prestador.nome,
            colecaoUsuario: 'prestadorServicos',
          ),
          body: _buildProfileContent(prestador),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              /* TODO: Adicionar ação principal */
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  // O resto do seu código (os métodos _build...) continua o mesmo

  Widget _buildProfileContent(PrestadorProfile prestador) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Text(
              '${prestador.areaAtuacao} ${prestador.nome}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text(
              'Serviços oferecidos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('servicos')
                  .where('prestadorId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Nenhum serviço cadastrado.'),
                    ),
                  );
                }

                final servicosDocs = snapshot.data!.docs;

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: servicosDocs.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final data = servicosDocs[index].data() as Map<String, dynamic>;
                    return _buildServiceCard(data);
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> servico) {
    final nome = servico['nome'] ?? 'Sem nome';
    final preco = servico['preco'] ?? 0.0;
    final imagemBase64 = servico['imagemBase64'] as String?;

    return Card(
      elevation: 0,
      color: const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imagemBase64 != null && imagemBase64.isNotEmpty
                    ? Image.memory(
                        UsuarioUtil.decodificarBase64(imagemBase64),
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Center(
                          child: Icon(Icons.image_not_supported, color: Colors.white70),
                        ),
                      )
                    : const Center(
                        child: Text(
                          '*Sem imagem*',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(nome, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'R\$${preco.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12, // espaço horizontal entre os botões
      runSpacing: 12, // espaço vertical quando quebram a linha
      children: [
        ElevatedButton.icon(
          onPressed: () {
            /* TODO */
          },
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Editar Itens'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF424242),
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton(
          onPressed: () {
            /* TODO */
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF424242),
            foregroundColor: Colors.white,
          ),
          child: const Text('Serviços Agendados'),
        ),
        ElevatedButton(
          onPressed: () {
            /* TODO */
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF424242),
            foregroundColor: Colors.white,
          ),
          child: const Text('Serviços Pendentes'),
        ),
      ],
    );
  }
}
