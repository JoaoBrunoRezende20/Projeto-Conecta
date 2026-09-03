import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/auth_wrapper.dart';
import '../auth/tela_cadastro_usuarios.dart';
import '/widgets/menu_lateral.dart';
import '/widgets/botao_notificacao.dart';
import 'tela_cadastro_servico_prestador.dart';
import 'tela_gerenciar_servicos_prestador.dart';
import '../../utils/usuario_util.dart';

// --- Modelos de Dados ---
class PrestadorProfile {
  final String uid;
  final String nome;
  final String areaAtuacao;
  final bool isOnline;

  PrestadorProfile({
    required this.uid,
    required this.nome,
    required this.areaAtuacao,
    required this.isOnline,
  });
}

// --- A Tela ---
class TelaInicialPrestador extends StatefulWidget {
  const TelaInicialPrestador({super.key});

  @override
  State<TelaInicialPrestador> createState() => _TelaInicialPrestadorState();
}

class _TelaInicialPrestadorState extends State<TelaInicialPrestador> {
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => AuthWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text("Erro de ID")));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('prestadorServicos')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null)
          return const Scaffold(
            body: Center(child: Text("Cadastro não encontrado.")),
          );

        // 1. LÓGICA DE VALIDAÇÃO (TRAVA DE ACESSO)
        final statusCadastro = data['statusCadastro'] ?? 'pendente';
        final motivosRejeicao = data['motivosRejeicao'] ?? '';

        if (statusCadastro == 'pendente') {
          return _buildTelaBloqueio(
            titulo: "Cadastro em Análise",
            mensagem:
                "Sua conta está em análise. Aguarde a aprovação do Administrador.",
            icone: Icons.hourglass_top,
            cor: Colors.orange,
            statusCadastro: statusCadastro,
            dadosCadastro: data,
          );
        }

        if (statusCadastro == 'rejeitado') {
          return _buildTelaBloqueio(
            titulo: "Cadastro Não Aprovado",
            mensagem:
                "Infelizmente seu cadastro não foi aprovado neste momento.\n\nMotivo:\n$motivosRejeicao\n\nPor favor, envie novos documentos para nova análise ou entre em contato com o suporte.",
            icone: Icons.error_outline,
            cor: Colors.red,
            statusCadastro: statusCadastro,
            dadosCadastro: data,
          );
        }

        // 2. SE APROVADO, CARREGA OS DADOS E MOSTRA O PERFIL
        final nomeFormatado = UsuarioUtil.getNomeCompleto(
          data,
          colecao: 'prestadorServicos',
        );
        final areaAtuacao = data['areaAtuacao'] ?? "Profissão não definida";
        final prestador = PrestadorProfile(
          uid: user.uid,
          nome: nomeFormatado, 
          areaAtuacao: areaAtuacao,
          isOnline: data['isOnline'] ?? false,
        );

        return _buildTelaAprovada(prestador);
      },
    );
  }

  // --- TELA DE BLOQUEIO (PENDENTE / REJEITADO) ---
  Widget _buildTelaBloqueio({
    required String titulo,
    required String mensagem,
    required IconData icone,
    required Color cor,
    required String statusCadastro,
    Map<String, dynamic>? dadosCadastro,
  }) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icone, size: 80, color: cor),
              const SizedBox(height: 24),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                mensagem,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Se o status for REJEITADO, exibe a opção de reenviar documentos abrindo a aba de cadastro preenchida
              if (statusCadastro == 'rejeitado') ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TelaCadastro(
                          tipoUsuario: 'prestador',
                          isReenvio: true,
                          dadosIniciais: dadosCadastro,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_document),
                  label: const Text('Reenviar Documentos para Análise'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Botão para voltar para a tela inicial de login
              OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar para a Tela Inicial'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[800],
                  side: BorderSide(color: Colors.grey[400]!),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TELA PRINCIPAL (APROVADO) ---
  Widget _buildTelaAprovada(PrestadorProfile prestador) {
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TelaCadastroServicoPrestador(),
            ),
          );
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

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
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text("Estou disponível (Online)", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Ative para os clientes saberem que você pode responder rápido."),
              value: prestador.isOnline,
              activeColor: Colors.green,
              secondary: Icon(
                prestador.isOnline ? Icons.circle : Icons.circle_outlined,
                color: prestador.isOnline ? Colors.green : Colors.grey,
              ),
              onChanged: (value) async {
                try {
                  await FirebaseFirestore.instance
                      .collection('prestadorServicos')
                      .doc(prestador.uid)
                      .update({'isOnline': value});
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao atualizar status: $e')),
                    );
                  }
                }
              },
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
                  .where(
                    'prestadorId',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                  )
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
                    final data =
                        servicosDocs[index].data() as Map<String, dynamic>;
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
    final imagem = (servico['imagemUrl'] ?? servico['imagemBase64']) as String?;

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
                child: imagem != null && imagem.isNotEmpty
                    ? UsuarioUtil.buildImageWidget(imagem, fit: BoxFit.cover)
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
            child: Text(
              nome,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
      spacing: 12,
      runSpacing: 12,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TelaGerenciarServicosPrestador(),
              ),
            );
          },
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Editar Itens'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF424242),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
