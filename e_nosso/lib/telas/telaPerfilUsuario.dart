import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelaPerfilUsuario extends StatefulWidget {
  const TelaPerfilUsuario({super.key});

  @override
  State<TelaPerfilUsuario> createState() => _TelaPerfilUsuarioState();
}

class _TelaPerfilUsuarioState extends State<TelaPerfilUsuario> {
  final _auth = FirebaseAuth.instance;

  String nome = "";
  String email = "";
  String telefone = "";
  String endereco = "";
  String tipoUsuario = "";

  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    final uid = _auth.currentUser!.uid;

    // === BUSCA DO TIPO DE USUÁRIO ===
    String tipo = await _getUserType(uid);
    tipoUsuario = tipo;

    // === BUSCA DOS DADOS DO USUÁRIO ===
    final doc = await FirebaseFirestore.instance
        .collection(tipo == 'comum'
        ? 'usuariosComuns'
        : tipo == 'lojista'
        ? 'lojistas'
        : tipo == 'prestador'
        ? 'prestadorServicos'
        : 'administrador')
        .doc(uid)
        .get();

    final data = doc.data();

    setState(() {
      nome = data?['nome'] ?? 'Nome não encontrado';
      email = data?['email'] ?? '';
      telefone = data?['telefone'] ?? '';
      endereco = data?['endereco'] ?? '';
      carregando = false;
    });
  }

  /// Mesma lógica usada na sua main.dart
  Future<String> _getUserType(String uid) async {
    final fs = FirebaseFirestore.instance;

    if ((await fs.collection('administrador').doc(uid).get()).exists) {
      return 'administrador';
    }
    if ((await fs.collection('lojistas').doc(uid).get()).exists) {
      return 'lojista';
    }
    if ((await fs.collection('prestadorServicos').doc(uid).get()).exists) {
      return 'prestador';
    }
    return 'comum';
  }

  @override
  Widget build(BuildContext context) {
    return carregando
        ? const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    )
        : Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepPurple),
              child: Text(
                "Menu - $tipoUsuario",
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Perfil"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Sair"),
              onTap: () => FirebaseAuth.instance.signOut(),
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),

      backgroundColor: Colors.white,

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // FOTO DO USUÁRIO
            Stack(
              alignment: Alignment.center,
              children: [
                const CircleAvatar(
                  radius: 75,
                  backgroundColor: Color(0xfff1f1f1),
                  child: Icon(
                    Icons.person,
                    size: 90,
                    color: Colors.black54,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 20,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.edit,
                          size: 16, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // NOME DO USUÁRIO
            Text(
              nome,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // CAMPOS
            _campoPerfil(
              titulo: "Email",
              valor: email,
              acaoEditar: () {},
            ),
            _campoPerfil(
              titulo: "Telefone",
              valor: telefone,
              acaoEditar: () {},
            ),
            _campoPerfil(
              titulo: "Endereço",
              valor: endereco,
              acaoEditar: () {},
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "Acessar histórico de compras",
                    style: TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.history, size: 20),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // WIDGET REUTILIZADO PARA OS CAMPOS
  Widget _campoPerfil({
    required String titulo,
    required String valor,
    required VoidCallback acaoEditar,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xffeaeaea),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    valor,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                GestureDetector(
                  onTap: acaoEditar,
                  child: const Icon(Icons.edit, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
