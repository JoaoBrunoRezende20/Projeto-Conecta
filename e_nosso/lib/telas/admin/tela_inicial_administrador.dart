import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/usuario_util.dart';
// Certifique-se que os nomes das classes dentro desses arquivos estão corretos
import 'tela_todos_usuarios.dart';
import 'tela_logs.dart';
import '../auth/tela_detalhes_cadastro.dart';

// Classe modelo para facilitar a manipulação dos dados
class UsuarioPendente {
  final String id;
  final String nome;
  final String tipo; // 'Lojista' ou 'Prestador de serviço'
  final Timestamp dataEnvio;
  final String cpfOuCnpj; // Adicionei para facilitar a busca por doc também

  UsuarioPendente({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.dataEnvio,
    required this.cpfOuCnpj,
  });
}

class TelaInicialAdministrador extends StatefulWidget {
  const TelaInicialAdministrador({super.key});

  @override
  State<TelaInicialAdministrador> createState() =>
      _TelaInicialAdministradorState();
}

class _TelaInicialAdministradorState extends State<TelaInicialAdministrador> {
  // --- VARIÁVEIS DE ESTADO PARA OS FILTROS ---
  bool _filtroLojistaAtivo = true;
  bool _filtroPrestadorAtivo = true;
  final TextEditingController _searchController = TextEditingController();
  String _termoBusca = '';

  @override
  void initState() {
    super.initState();
    // Adiciona listener para atualizar a busca em tempo real enquanto digita
    _searchController.addListener(() {
      setState(() {
        _termoBusca = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Função que busca e FILTRA os usuários
  Future<List<UsuarioPendente>> _buscarUsuariosPendentes() async {
    final firestore = FirebaseFirestore.instance;
    final List<UsuarioPendente> usuarios = [];

    // 1. Busca Lojistas (SE O FILTRO ESTIVER ATIVO)
    if (_filtroLojistaAtivo) {
      final lojistasSnapshot = await firestore
          .collection('lojistas')
          .where('statusCadastro', isEqualTo: 'pendente')
          .get();

      for (var doc in lojistasSnapshot.docs) {
        final data = doc.data();
        usuarios.add(
          UsuarioPendente(
            id: doc.id,
            nome:
                UsuarioUtil.getNomeCompleto(
                  data,
                  tipo: 'Lojista',
                  colecao: 'lojistas',
                ),
            tipo: 'Lojista',
            dataEnvio: data['dataCriacao'] ?? Timestamp.now(),
            cpfOuCnpj: data['cnpj'] ?? '',
          ),
        );
      }
    }

    // 2. Busca Prestadores (SE O FILTRO ESTIVER ATIVO)
    if (_filtroPrestadorAtivo) {
      final prestadoresSnapshot = await firestore
          .collection('prestadorServicos')
          .where('statusCadastro', isEqualTo: 'pendente')
          .get();

      for (var doc in prestadoresSnapshot.docs) {
        final data = doc.data();
        usuarios.add(
          UsuarioPendente(
            id: doc.id,
            nome: UsuarioUtil.getNomeCompleto(data, tipo: 'Prestador de serviço', colecao: 'prestadorServicos'),
            tipo: 'Prestador de serviço',
            dataEnvio: data['dataCriacao'] ?? Timestamp.now(),
            cpfOuCnpj: data['cpf'] ?? '',
          ),
        );
      }
    }

    // 3. Aplica o Filtro de Texto (Barra de Pesquisa)
    if (_termoBusca.isNotEmpty) {
      return usuarios.where((u) {
        final nomeLower = u.nome.toLowerCase();
        final docLower = u.cpfOuCnpj.toLowerCase();
        return nomeLower.contains(_termoBusca) ||
            docLower.contains(_termoBusca);
      }).toList();
    }

    // Ordena por data (mais antigo primeiro, ou mais recente, como preferir)
    usuarios.sort((a, b) => b.dataEnvio.compareTo(a.dataEnvio));

    return usuarios;
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // --- FUNÇÃO DO POP-UP DE FILTRO ---
  void _mostrarFiltros() {
    showDialog(
      context: context,
      builder: (context) {
        // Variáveis temporárias para controlar o estado DENTRO do dialog antes de confirmar
        bool tempLojista = _filtroLojistaAtivo;
        bool tempPrestador = _filtroPrestadorAtivo;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Center(
                child: Text(
                  'Filtros',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Tipos de usuário',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Checkbox Lojista
                  CheckboxListTile(
                    title: const Text('Lojista'),
                    value: tempLojista,
                    activeColor: Colors.black87,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) {
                      setStateDialog(() => tempLojista = val ?? true);
                    },
                  ),

                  // Checkbox Prestador
                  CheckboxListTile(
                    title: const Text('Prestador'),
                    value: tempPrestador,
                    activeColor: Colors.black87,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) {
                      setStateDialog(() => tempPrestador = val ?? true);
                    },
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Voltar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Atualiza o estado da TELA PRINCIPAL com as escolhas
                    setState(() {
                      _filtroLojistaAtivo = tempLojista;
                      _filtroPrestadorAtivo = tempPrestador;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.grey[600], // Cor mais escura igual imagem
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF424242),
        title: const Text(
          'Cadastros pendentes',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
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

            // --- BARRA DE PESQUISA COM FILTRO ---
            _buildSearchBar(),

            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<UsuarioPendente>>(
                // Agora chama a função que respeita os filtros
                future: _buscarUsuariosPendentes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Erro ao carregar usuários.'),
                    );
                  }

                  // Se a lista estiver vazia (seja por não ter dados ou pelos filtros)
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_list_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Nenhum cadastro encontrado com esses filtros.',
                          ),
                        ],
                      ),
                    );
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
      bottomNavigationBar: _buildBottomButtons(context),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Pesquise por nome',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        // ÍCONE DE FILTRO FUNCIONAL
        suffixIcon: IconButton(
          icon: const Icon(
            Icons.tune,
            color: Colors.black87,
          ), // Ícone de "ajustes"
          onPressed: _mostrarFiltros,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildUserCard(UsuarioPendente usuario) {
    final dataFormatada =
        '${usuario.dataEnvio.toDate().day}/${usuario.dataEnvio.toDate().month}/${usuario.dataEnvio.toDate().year}';

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              // Expanded evita overflow de texto longo
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nome: ${usuario.nome}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Tipo: ${usuario.tipo}'),
                  Row(
                    children: [
                      const Text('Status: ', style: TextStyle(fontSize: 12)),
                      Text(
                        'PENDENTE',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Envio: $dataFormatada',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 35, // Botão mais compacto
                  child: ElevatedButton(
                    onPressed: () {
                      String colecao = usuario.tipo == 'Lojista'
                          ? 'lojistas'
                          : 'prestadorServicos';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TelaDetalhesCadastro(
                            usuarioId: usuario.id,
                            colecao: colecao,
                            nomeUsuario: usuario.nome,
                          ),
                        ),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Ver documentos',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    final ButtonStyle darkButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF424242),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(vertical: 12),
      elevation: 3,
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaGerenciarUsuarios(),
                  ),
                );
              },
              style: darkButtonStyle,
              child: const Text(
                'Ver todos usuarios',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                print("Botão Cadastrar clicado");
              },
              style: darkButtonStyle,
              child: const Text(
                'Cadastrar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaLogsAdm()),
                );
              },
              style: darkButtonStyle,
              child: const Text(
                'Ver Historico',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
