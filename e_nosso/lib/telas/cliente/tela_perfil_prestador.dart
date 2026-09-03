import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tela_detalhes_servico.dart';

class TelaPerfilPrestador extends StatefulWidget {
  final String prestadorId;

  const TelaPerfilPrestador({super.key, required this.prestadorId});

  @override
  State<TelaPerfilPrestador> createState() => _TelaPerfilPrestadorState();
}

class _TelaPerfilPrestadorState extends State<TelaPerfilPrestador> {
  Map<String, dynamic>? _dadosPrestador;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarPrestador();
  }

  Future<void> _carregarPrestador() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('prestadorServicos')
          .doc(widget.prestadorId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _dadosPrestador = doc.data();
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black54, width: 1.5),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dadosPrestador == null
          ? const Center(child: Text('Prestador não encontrado.'))
          : _buildBody(),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final data = _dadosPrestador!;
    final nome = (data['nome'] ?? data['nomeCompleto'] ?? 'Prestador')
        .toString();
    final sobrenome = (data['sobrenome'] ?? '').toString();
    final nomeCompleto = '$nome${sobrenome.isNotEmpty ? ' $sobrenome' : ''}';
    final areaAtuacao = (data['areaAtuacao'] ?? 'Prestador autônomo')
        .toString();
    final descricao =
        (data['descricaoServicos'] ??
                data['descricao'] ??
                data['areaAtuacao'] ??
                'Descrição geral dos serviços prestados')
            .toString();
    final telefone = (data['telefone'] ?? 'Não informado').toString();
    final email = (data['email'] ?? 'Não informado').toString();
    final qualificacoes = (data['qualificacoes'] ?? '').toString();
    final disponibilidade =
        (data['disponibilidadeAtendimento'] ?? 'Não informado').toString();
    final mediaAvaliacoes =
        (data['mediaEstrelas'] ?? data['mediaAvaliacoes'] ?? 0.0).toDouble();
    final int qtdAvaliacoes =
        (data['quantidadeAvaliacoes'] as num?)?.toInt() ?? 0;
    final fotoPerfilUrl = data['fotoPerfilUrl'] as String?;
    final bool isOnline = data['isOnline'] ?? false;

    // Área de atendimento (bairros)
    String areaAtendimento = 'Não informado';
    if (data['areaAtendimento'] is List) {
      final bairros = List<String>.from(data['areaAtendimento']);
      if (bairros.isNotEmpty) {
        areaAtendimento = bairros.join(', ');
      }
    }

    // Fotos do portfólio salvas no campo 'fotosPortfolio' como lista de URLs
    final List<dynamic> fotosRaw = data['fotosPortfolio'] ?? [];
    final List<String> fotos = fotosRaw.map((e) => e.toString()).toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cabeçalho: avatar + nome + avaliação ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            fotoPerfilUrl != null && fotoPerfilUrl.isNotEmpty
                            ? NetworkImage(fotoPerfilUrl)
                            : null,
                        child: fotoPerfilUrl == null || fotoPerfilUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 36,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      // Nome, avaliação e tipo
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nomeCompleto,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: isOnline ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOnline ? "Online" : "Offline",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isOnline ? Colors.green[700] : Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  mediaAvaliacoes > 0
                                      ? '${mediaAvaliacoes.toStringAsFixed(1)} ($qtdAvaliacoes)'
                                      : 'Sem avaliações',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              areaAtuacao,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, indent: 20, endIndent: 20),

                // ── Sobre o Prestador ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        'Sobre o Prestador',
                        Icons.person_outline,
                      ),
                      Text(
                        descricao,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      if (qualificacoes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.school_outlined,
                          'Qualificações',
                          qualificacoes,
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(height: 1, indent: 20, endIndent: 20),

                // ── Horários de Atendimento ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        'Horários de Atendimento',
                        Icons.access_time,
                      ),
                      if (disponibilidade != 'Não informado') ...[
                        ...disponibilidade.split(', ').map((item) {
                          final partes = item.split(': ');
                          if (partes.length == 2) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      partes[0],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    partes[1],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Text(
                            item,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          );
                        }),
                      ] else
                        const Text(
                          'Horários não informados.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                    ],
                  ),
                ),

                const Divider(height: 1, indent: 20, endIndent: 20),

                // ── Informações para Contato ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        'Informações para Contato',
                        Icons.contact_phone_outlined,
                      ),
                      _buildInfoRow(Icons.phone_outlined, 'Telefone', telefone),
                      _buildInfoRow(Icons.email_outlined, 'Email', email),
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        'Área de Atendimento',
                        areaAtendimento,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Botões Mensagem / Ir para catálogo ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final tel = telefone;
                            if (tel.isNotEmpty && tel != 'Não informado') {
                              final numWhats = tel.replaceAll(
                                RegExp(r'[^0-9]'),
                                '',
                              );
                              final uri = Uri.parse(
                                "https://wa.me/55$numWhats",
                              );
                              launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Telefone não informado pelo prestador.',
                                  ),
                                ),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.black38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Mensagem',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TelaDetalhesServico(
                                  prestador: {
                                    'prestadorId': widget.prestadorId,
                                    'nome': nomeCompleto,
                                    'telefone': telefone,
                                  },
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.black38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Ir para catálogo',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),


              ],
            ),
          ),
        ),
      ],
    );
  }
}
