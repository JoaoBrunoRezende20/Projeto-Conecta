import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'telaTipoUsuario.dart';
import 'package:e_nosso/telas/telaMenuLateral.dart';
import 'telaBotaoNotificacao.dart';

// --- Modelos de Dados (para organizar a informação) ---

// Guarda os dados do perfil do prestador
class PrestadorProfile {
  final String nome;
  final String areaAtuacao;

  PrestadorProfile({required this.nome, required this.areaAtuacao});
}

// Guarda os dados de um serviço específico
class ServicoItem {
  final String imagemUrl;
  final String nome;
  final double preco;

  ServicoItem({required this.imagemUrl, required this.nome, required this.preco});
}

// --- A Tela ---

class TelaInicialPrestador extends StatefulWidget {
  const TelaInicialPrestador({super.key});

  @override
  State<TelaInicialPrestador> createState() => _TelaInicialPrestadorState();
}

class _TelaInicialPrestadorState extends State<TelaInicialPrestador> {
  PrestadorProfile? _prestador;
  List<ServicoItem> _servicos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Função para buscar todos os dados do Firebase
  Future<void> _fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // TODO: Conectar com o Firestore para buscar dados reais
    // Por enquanto, usaremos dados de exemplo (mock)
    setState(() {
      _prestador = PrestadorProfile(
        nome: "Fulano de Tal",
        areaAtuacao: "Eletricista",
      );

      _servicos = [
        ServicoItem(imagemUrl: "", nome: "Serviço 1", preco: 30.00),
        ServicoItem(imagemUrl: "", nome: "Serviço 2", preco: 45.00),
        ServicoItem(imagemUrl: "", nome: "Serviço 3", preco: 70.00),
        ServicoItem(imagemUrl: "", nome: "Serviço 4", preco: 30.00),
        ServicoItem(imagemUrl: "", nome: "Serviço 5", preco: 45.00),
        ServicoItem(imagemUrl: "", nome: "Serviço 6", preco: 70.00),
      ];

      _isLoading = false;
    });
  }

  // <<< AQUI ESTÁ A CORREÇÃO >>>
  // A função de Logout agora é muito mais simples.
  Future<void> _signOut() async {
    // Apenas avisa ao Firebase para deslogar.
    // O AuthWrapper no main.dart vai ouvir essa mudança e
    // automaticamente redirecionar para a TelaTipoUsuario.
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
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
        /*leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          /*onPressed: () { /* TODO: Abrir Drawer */ },*/
          onPressed: (){ //**********
            Scaffold.of(context).openDrawer();
          },
        ),*/
         */
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            // Chama a nova função de logout
            onPressed: _signOut,
          ),
          BotaoNotificacao(colecaoUsuario: 'prestadorServicos'), // <--- AQUI
          const SizedBox(width: 10),
        ],
      ),

    //drawer: const MenuLateral(), //**********
    drawer: MenuLateral(nomeUsuario: _prestador?.nome ?? "Usuário"),
    body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildProfileContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () { /* TODO: Adicionar ação principal */ },
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // O resto do seu código (os métodos _build...) continua o mesmo

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Text(
              '${_prestador?.areaAtuacao ?? ''} ${_prestador?.nome ?? ''}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text(
              'Serviços oferecidos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: _servicos.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildServiceCard(_servicos[index]);
              },
            ),
            const SizedBox(height: 24),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(ServicoItem servico) {
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
              child: const Center(
                child: Text(
                  '*Imagens do serviço*',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(servico.nome, textAlign: TextAlign.center),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'R\$${servico.preco.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () { /* TODO */ },
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Editar Itens'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF424242),
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton(
          onPressed: () { /* TODO */ },
          child: const Text('Serviços Agendados'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF424242),
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton(
          onPressed: () { /* TODO */ },
          child: const Text('Serviços Pendentes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF424242),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}