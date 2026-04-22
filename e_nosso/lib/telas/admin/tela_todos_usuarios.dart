import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../lojista/tela_admin_conteudo_lojista.dart';
import '../prestador/tela_admin_conteudo_prestador.dart';
import '../auth/tela_detalhes_cadastro.dart'; // Import da tela de avaliação

class TelaGerenciarUsuarios extends StatefulWidget {
  const TelaGerenciarUsuarios({super.key});

  @override
  State<TelaGerenciarUsuarios> createState() => _TelaGerenciarUsuariosState();
}

class _TelaGerenciarUsuariosState extends State<TelaGerenciarUsuarios>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // --- FUNÇÕES DE LOGS ---
  Future<void> _gerarLog(String uidAlvo, String nomeAlvo, String acao, String justificativa) async {
    await FirebaseFirestore.instance.collection('logsAdministrativos').add({
      'dataHora': FieldValue.serverTimestamp(),
      'administradorUid': _currentUser?.uid,
      'administradorNome': 'Admin',
      'usuarioAfetadoUid': uidAlvo,
      'usuarioAfetadoNome': nomeAlvo,
      'acao': acao == 'EXCLUSAO',
      'justificativa': justificativa,
      'tipoAcao': acao,
    });
  }

  // --- FUNÇÃO DE EXCLUIR USUÁRIO ---
  void _confirmarExclusao(String uid, String nome, String colecao) {
    final justificativaController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('EXCLUIR $nome?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Essa ação apagará os dados do usuário do banco de dados. Isso é irreversível!',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: justificativaController,
              decoration: const InputDecoration(labelText: 'Motivo da exclusão', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (justificativaController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Justificativa obrigatória.')));
                return;
              }
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection(colecao).doc(uid).delete();
              _gerarLog(uid, nome, 'EXCLUSAO_CONTA', justificativaController.text);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário excluído.')));
            },
            child: const Text('EXCLUIR CONTA', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- PROMOVER ADMIN ---
  Future<void> _toggleAdmin(String uid, String nome, bool virarAdmin) async {
    await FirebaseFirestore.instance.collection('usuarioComum').doc(uid).update({'tipo': virarAdmin ? 'admin' : 'comum'});
    _gerarLog(uid, nome, virarAdmin ? 'PROMOCAO_ADMIN' : 'REBAIXAMENTO', 'Alteração de nível de acesso');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão Total'),
        backgroundColor: const Color(0xFF424242),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Usuários', icon: Icon(Icons.person)),
            Tab(text: 'Lojistas', icon: Icon(Icons.store)),
            Tab(text: 'Prestadores', icon: Icon(Icons.engineering)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListaComuns(),
          _buildListaEspeciais('lojistas'),
          _buildListaEspeciais('prestadorServicos'),
        ],
      ),
    );
  }

  // ABA 1: USUÁRIOS COMUNS
  Widget _buildListaComuns() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarioComum').orderBy('nome').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final usuarios = snapshot.data!.docs;

        return ListView.builder(
          itemCount: usuarios.length,
          itemBuilder: (context, index) {
            final dados = usuarios[index].data() as Map<String, dynamic>;
            final uid = usuarios[index].id;
            final nome = '${dados['nome']} ${dados['sobrenome'] ?? ''}';
            final isAdmin = dados['tipo'] == 'admin';
            final isMe = uid == _currentUser?.uid;

            return ListTile(
              title: Text(nome),
              subtitle: Text(dados['email'] ?? ''),
              trailing: isMe
                  ? const Chip(label: Text('Você'))
                  : IconButton(
                      icon: Icon(isAdmin ? Icons.security : Icons.person_outline, color: isAdmin ? Colors.blue : Colors.grey),
                      onPressed: () => _toggleAdmin(uid, nome, !isAdmin),
                    ),
            );
          },
        );
      },
    );
  }

  // ABA 2 e 3: LOJISTAS E PRESTADORES
  Widget _buildListaEspeciais(String colecao) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(colecao).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Nenhum usuário encontrado.'));

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final dados = doc.data() as Map<String, dynamic>;
            final uid = doc.id;

            String nome = 'Sem nome';
            if (colecao == 'lojistas') {
              nome = dados['razaoSocial'] ?? dados['dadosDoResponsavel']?['nome'] ?? 'Lojista';
            } else {
              nome = '${dados['nome']} ${dados['sobrenome']}';
            }

            // Identifica se está pendente
            final statusCadastro = dados['statusCadastro'] ?? 'pendente';
            final isPendente = statusCadastro == 'pendente';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: colecao == 'lojistas' ? Colors.orange[100] : Colors.blue[100],
                child: Icon(colecao == 'lojistas' ? Icons.store : Icons.build, color: Colors.black54),
              ),
              title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(isPendente ? 'Aguardando Avaliação' : 'Toque para gerenciar conteúdo'),
              
              // CLIQUE NO ITEM
              onTap: () {
                if (isPendente) {
                  // Se estiver pendente, abre a tela de Aprovação/Rejeição
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => TelaDetalhesCadastro(usuarioId: uid, colecao: colecao, nomeUsuario: nome),
                  ));
                } else {
                  // Se já estiver aprovado, abre o gerenciador de conteúdo
                  if (colecao == 'lojistas') {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => TelaAdminConteudoLojista(lojistaId: uid, nomeLojista: nome),
                    ));
                  } else {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => TelaAdminConteudoPrestador(uidPrestador: uid, nomePrestador: nome),
                    ));
                  }
                }
              },

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPendente)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
                      child: const Text('Pendente', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () => _confirmarExclusao(uid, nome, colecao),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}