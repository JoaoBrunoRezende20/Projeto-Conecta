import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'telaTipoUsuario.dart';

// Classe modelo para facilitar a manipulação dos dados
class UsuarioPendente {
  final String id;
  final String nome;
  final String tipo;
  final Timestamp dataEnvio;

  UsuarioPendente({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.dataEnvio,
  });
}

class TelaInicialAdministrador extends StatefulWidget {
  const TelaInicialAdministrador({super.key});

  @override
  State<TelaInicialAdministrador> createState() => _TelaInicialAdministradorState();
}

class _TelaInicialAdministradorState extends State<TelaInicialAdministrador> {

  // Função que busca os usuários pendentes nas duas coleções
  Future<List<UsuarioPendente>> _buscarUsuariosPendentes() async {
    final firestore = FirebaseFirestore.instance;

    final lojistasSnapshot = await firestore
        .collection('lojistas')
        .where('statusCadastro', isEqualTo: 'pendente')
        .get();

    final prestadoresSnapshot = await firestore
        .collection('prestadorServicos')
        .where('statusCadastro', isEqualTo: 'pendente')
        .get();

    final List<UsuarioPendente> usuarios = [];

    for (var doc in lojistasSnapshot.docs) {
      final data = doc.data();
      usuarios.add(UsuarioPendente(
        id: doc.id,
        nome: data['dadosDoResponsavel']?['nome'] ?? 'Nome não encontrado',
        tipo: 'Lojista',
        dataEnvio: data['dataCriacao'] ?? Timestamp.now(),
      ));
    }

    for (var doc in prestadoresSnapshot.docs) {
      final data = doc.data();
      usuarios.add(UsuarioPendente(
        id: doc.id,
        nome: data['nome'] ?? 'Nome não encontrado',
        tipo: 'Prestador de serviço',
        dataEnvio: data['dataCriacao'] ?? Timestamp.now(),
      ));
    }

    return usuarios;
  }

  // <<< AQUI ESTÁ A CORREÇÃO >>>
  // A função de Logout agora apenas desloga, sem fazer navegação manual.
  Future<void> _signOut() async {
    // Apenas avisa ao Firebase para deslogar.
    // O AuthWrapper no main.dart vai ouvir essa mudança e
    // automaticamente redirecionar para a TelaTipoUsuario.
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF424242),
        title: const Text('Cadastros pendentes', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          // Chama a nova função de logout (que não precisa mais do 'context')
          onPressed: _signOut,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Usuários com cadastros pendentes',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<UsuarioPendente>>(
                future: _buscarUsuariosPendentes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Erro ao carregar usuários.'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Nenhum cadastro pendente.'));
                  }

                  final usuarios = snapshot.data!;

                  return ListView.builder(
                    itemCount: usuarios.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(usuarios[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Pesquise por nome, CPF, CNPJ, email ou código',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: const Icon(Icons.tune, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildUserCard(UsuarioPendente usuario) {
    final dataFormatada = '${usuario.dataEnvio.toDate().day}/${usuario.dataEnvio.toDate().month}/${usuario.dataEnvio.toDate().year}';

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nome: ${usuario.nome}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Tipo de usuário: ${usuario.tipo}'),
                Row(
                  children: [
                    const Text('Status: '),
                    Text(
                      'PENDENTE',
                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Envio: $dataFormatada'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implementar lógica para ver documentos do usuário
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Ver documentos'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar lógica do botão Voltar
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF424242),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar lógica do botão Cadastrar (talvez um novo admin?)
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF424242),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    );
  }
}

