import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tela_produtos_disponiveis.dart'; // Para acessar carrinhoGlobal e lojaIdDoCarrinho
import '../../utils/carrinho_util.dart';

class TelaDetalhesServico extends StatefulWidget {
  final Map<String, dynamic> prestador; // Dados do prestador e seus serviços

  const TelaDetalhesServico({super.key, required this.prestador});

  @override
  State<TelaDetalhesServico> createState() => _TelaDetalhesServicoState();
}

class _TelaDetalhesServicoState extends State<TelaDetalhesServico> {
  DateTime? dataSelecionada;
  Set<int> servicosSelecionados = {}; // Armazena os índices dos serviços escolhidos

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.menu, color: Colors.black),
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
                  const Text(
                    "Selecione os serviços que deseja agendar:",
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 15),

                  // Grid de Serviços (3 colunas)
                  Expanded(
                    child: GridView.builder(
                      itemCount: 9, // Mockup com 9 opções
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 15,
                            childAspectRatio: 0.7,
                          ),
                      itemBuilder: (context, index) {
                        bool estaSelecionado = servicosSelecionados.contains(index);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (estaSelecionado) {
                                servicosSelecionados.remove(index);
                              } else {
                                servicosSelecionados.add(index);
                              }
                            });
                          },
                          child: Column(
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: estaSelecionado 
                                            ? Colors.green[100] // Destaque se selecionado
                                            : Colors.grey[600],
                                        borderRadius: BorderRadius.circular(15),
                                        border: estaSelecionado
                                            ? Border.all(color: Colors.green, width: 3)
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          "*Imagens do serviço",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: estaSelecionado ? Colors.green[800] : Colors.white,
                                            fontSize: 8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (estaSelecionado)
                                      const Positioned(
                                        top: 5,
                                        right: 5,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.green,
                                          radius: 10,
                                          child: Icon(Icons.check, color: Colors.white, size: 12),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Serviço ${index + 1}",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: estaSelecionado ? FontWeight.bold : FontWeight.w500,
                                  color: estaSelecionado ? Colors.green[900] : Colors.black,
                                ),
                              ),
                              Text(
                                "R\$${30 + (index * 15)},00",
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selecionarDataEAgendar(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: servicosSelecionados.isEmpty 
                          ? Colors.grey[400] 
                          : Colors.grey[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(
                      servicosSelecionados.isEmpty 
                        ? "Selecione algo" 
                        : "Agendar (${servicosSelecionados.length})",
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final nome = widget.prestador['nome'] ?? "Prestador";
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Iniciando conversa com $nome...")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text("Falar com"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selecionarDataEAgendar(BuildContext context) async {
    if (servicosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, selecione pelo menos um serviço.")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final isVisitor = user == null || user.isAnonymous;

    if (isVisitor) {
      _mostrarDialogoLogin();
      return;
    }

    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
      helpText: "Selecione uma data para o serviço",
    );

    if (data != null) {
      setState(() {
        dataSelecionada = data;
      });
      _finalizarAgendamento();
    }
  }

  void _finalizarAgendamento() {
    final String? prestadorId = widget.prestador['id'];
    if (prestadorId == null) return;

    final dataFormatada = "${dataSelecionada!.day}/${dataSelecionada!.month}";
    
    setState(() {
      for (int index in servicosSelecionados) {
        // Criamos um ID único para cada serviço do prestador no carrinho
        // Ex: "ID_PRESTADOR_SERV_1"
        final String itemKey = "${prestadorId}_serv_$index";
        final String nomeServico = "Serviço ${index + 1}";
        final double preco = 30.0 + (index * 15);

        carrinhoGlobal[itemKey] = {
          'nome': "${widget.prestador['nome']} - $nomeServico ($dataFormatada)",
          'preco': preco,
          'quantidade': 1,
        };
      }
    });

    CarrinhoUtil.salvarCarrinho(carrinhoGlobal, lojaIdDoCarrinho);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${servicosSelecionados.length} serviços agendados para $dataFormatada!"),
        backgroundColor: Colors.green,
      ),
    );

    // Limpar seleção após agendar
    setState(() {
      servicosSelecionados.clear();
    });
  }

  void _mostrarDialogoLogin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Autenticação necessária"),
        content: const Text("Por favor, faça login ou crie uma conta para agendar serviços."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
