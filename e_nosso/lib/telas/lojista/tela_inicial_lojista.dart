import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/auth_wrapper.dart';
import '../auth/tela_cadastro_usuarios.dart';
import '/widgets/botao_notificacao.dart';
import 'package:e_nosso/widgets/menu_lateral.dart';
import 'abas/aba_produtos_lojista.dart';
import 'abas/aba_pedidos_lojista.dart';

// --- CLASSE PRODUTO ---
class Produto {
  final String id;
  final String nome;
  final String descricao;
  final double preco;
  final int estoque;
  bool ativo;

  Produto({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.estoque,
    required this.ativo,
  });

  factory Produto.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Produto(
      id: doc.id,
      nome: data['nome'] ?? 'Nome indisponível',
      descricao: data['descricao'] ?? '',
      preco: (data['preco'] ?? 0).toDouble(),
      estoque: data['estoque'] ?? 0,
      ativo: data['ativo'] ?? false,
    );
  }
}

class TelaInicialLojista extends StatefulWidget {
  const TelaInicialLojista({super.key});

  @override
  State<TelaInicialLojista> createState() => _TelaInicialLojistaState();
}

class _TelaInicialLojistaState extends State<TelaInicialLojista> {
  final String? lojistaId = FirebaseAuth.instance.currentUser?.uid;

  // Controle de Abas: 0 (Produtos), 1 (Pedidos)
  int _indiceAbaAtual = 0;

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => AuthWrapper()),
        (route) => false,
      );
    }
  }

  // --- TRAVA DE ACESSO PARCIAL (StreamBuilder Principal) ---
  @override
  Widget build(BuildContext context) {
    if (lojistaId == null) {
      return const Scaffold(body: Center(child: Text("Erro de ID")));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lojistas')
          .doc(lojistaId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final dadosLojista = snapshot.data!.data() as Map<String, dynamic>?;
        if (dadosLojista == null) {
          return const Scaffold(
            body: Center(child: Text("Cadastro não encontrado.")),
          );
        }

        final statusCadastro = dadosLojista['statusCadastro'] ?? 'pendente';
        final motivosRejeicao = dadosLojista['motivosRejeicao'] ?? '';

        if (statusCadastro == 'pendente') {
          return _buildTelaBloqueio(
            titulo: "Cadastro em Análise",
            mensagem:
                "Sua conta está em análise. Aguarde a aprovação do Administrador.",
            icone: Icons.hourglass_top,
            cor: Colors.orange,
            statusCadastro: statusCadastro,
            dadosCadastro: dadosLojista,
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
            dadosCadastro: dadosLojista,
          );
        }

        // Se Aprovado, mostra o App Completo
        return _buildTelaAprovada();
      },
    );
  }

  // Interface de Validação Atualizada
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
                          tipoUsuario: 'lojista',
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

  // --- O PAINEL DE TRABALHO COMPLETO ---
  Widget _buildTelaAprovada() {
    String tituloApp = 'Meus Produtos';
    if (_indiceAbaAtual == 1) tituloApp = 'Pedidos Recebidos';

    return Scaffold(
      backgroundColor: Colors.white,

      // --- CONFIGURAÇÃO DO MENU LATERAL ---
      drawer: MenuLateral(
        nomeUsuario:
            FirebaseAuth.instance.currentUser?.displayName ?? 'Lojista',
        urlFotoPerfil: FirebaseAuth.instance.currentUser?.photoURL,
        colecaoUsuario: 'lojistas',
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        // --- BOTÃO DE GATILHO (Hambúrguer) ---
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),

        title: Text(tituloApp, style: const TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _signOut,
          ),
          BotaoNotificacao(colecaoUsuario: 'lojistas'),
          const SizedBox(width: 10),
        ],
      ),

      // Alternância de Abas usando Widgets extraídos
      body: _indiceAbaAtual == 0
          ? AbaProdutosLojista(lojistaId: lojistaId!)
          : AbaPedidosLojista(lojistaId: lojistaId!),

      // Barra Inferior
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _indiceAbaAtual,
        onTap: (index) => setState(() => _indiceAbaAtual = index),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Produtos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
        ],
      ),
    );
  }
}
