import 'dart:convert'; // Para decodificar as imagens Base64
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TelaDetalhesCadastro extends StatefulWidget {
  final String usuarioId;
  final String colecao; // 'lojistas' ou 'prestadorServicos'
  final String nomeUsuario; // Apenas para o título da AppBar

  const TelaDetalhesCadastro({
    super.key,
    required this.usuarioId,
    required this.colecao,
    required this.nomeUsuario,
  });

  @override
  State<TelaDetalhesCadastro> createState() => _TelaDetalhesCadastroState();
}

class _TelaDetalhesCadastroState extends State<TelaDetalhesCadastro> {
  bool _isLoading = false;
  final _currentUser = FirebaseAuth.instance.currentUser;
  // --- FUNÇÃO PARA ENVIAR NOTIFICAÇÃO ---
  Future<void> _enviarNotificacaoUsuario({
    required String titulo,
    required String mensagem,
    required String tipo, // 'aprovado' ou 'rejeitado'
  }) async {
    // Escreve na sub-coleção 'notificacoes' dentro do documento do usuário
    await FirebaseFirestore.instance
        .collection(widget.colecao) // 'lojistas' ou 'prestadorServicos'
        .doc(widget.usuarioId)
        .collection('notificacoes')
        .add({
      'titulo': titulo,
      'mensagem': mensagem,
      'tipo': tipo,
      'lida': false, // Começa não lida para ativar o badge
      'data': FieldValue.serverTimestamp(),
    });
  }
  // --- LÓGICA DE APROVAÇÃO ---
  Future<void> _aprovarCadastro() async {
    setState(() => _isLoading = true);
    try {
      // 1. Atualiza o status do usuário
      await FirebaseFirestore.instance.collection(widget.colecao).doc(widget.usuarioId).update({
        'statusCadastro': 'aprovado',
        'status': true, // Ativa o usuário no app
        'motivosRejeicao': FieldValue.delete(), // Limpa rejeições anteriores se houver
      });
      // Envia notificação
      await _enviarNotificacaoUsuario(
        titulo: 'Cadastro Aprovado! 🚀',
        mensagem: 'Parabéns! Seu cadastro foi validado. Você já pode acessar todas as funções.',
        tipo: 'aprovado',
      );
      // 2. Gera Log
      await _gerarLog(true, "Cadastro validado e aprovado.");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadastro APROVADO com sucesso!'), backgroundColor: Colors.green));
        Navigator.pop(context); // Volta para a lista
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LÓGICA DE REJEIÇÃO (COM DIALOG) ---
  void _mostrarDialogoRejeicao() {
    final justificativaController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeitar Cadastro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Por favor, informe o motivo da rejeição para o usuário corrigir:'),
            const SizedBox(height: 10),
            TextField(
              controller: justificativaController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ex: Documento ilegível, CNPJ inválido...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (justificativaController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A justificativa é obrigatória.')));
                return;
              }
              Navigator.pop(ctx);
              _rejeitarCadastro(justificativaController.text.trim());
            },
            child: const Text('Confirmar Rejeição'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejeitarCadastro(String motivo) async {
    setState(() => _isLoading = true);
    try {
      // 1. Atualiza status para rejeitado e salva o motivo
      await FirebaseFirestore.instance.collection(widget.colecao).doc(widget.usuarioId).update({
        'statusCadastro': 'rejeitado',
        'status': false,
        'motivosRejeicao': motivo,
      });
      // Envia notificaçao
      await _enviarNotificacaoUsuario(
        titulo: 'Atenção: Cadastro Rejeitado',
        mensagem: 'Houve uma pendência: $motivo. Por favor, corrija e envie novamente.',
        tipo: 'rejeitado',
      );
      // 2. Gera Log
      await _gerarLog(false, motivo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadastro REJEITADO.'), backgroundColor: Colors.red));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _gerarLog(bool aprovado, String justificativa) async {
    await FirebaseFirestore.instance.collection('logsAdministrativos').add({
      'dataHora': FieldValue.serverTimestamp(),
      'administradorUid': _currentUser?.uid,
      'administradorNome': 'Admin', // Idealmente buscar o nome do admin
      'usuarioAfetadoUid': widget.usuarioId,
      'usuarioAfetadoNome': widget.nomeUsuario,
      'acao': aprovado,
      'justificativa': justificativa,
      'tipoUsuario': widget.colecao,
    });
  }

  // --- WIDGETS DE VISUALIZAÇÃO ---

  // Decodifica Base64 e mostra imagem
  Widget _buildImagemBase64(String base64String) {
    try {
      // Remove o cabeçalho se existir (ex: "data:image/jpeg;base64,")
      String limpa = base64String;
      if (base64String.contains(',')) {
        limpa = base64String.split(',').last;
      }
      return Container(
        margin: const EdgeInsets.only(right: 8),
        width: 120,
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(limpa),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox(width: 100, child: Center(child: Text('Erro na imagem')));
    }
  }

  Widget _buildSecaoTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF424242))),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nomeUsuario),
        backgroundColor: const Color(0xFF424242),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection(widget.colecao).doc(widget.usuarioId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('Erro ao carregar dados'));
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text('Usuário não encontrado'));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final isLojista = widget.colecao == 'lojistas';

          // Extração segura de listas de imagens
          List<dynamic> docsImagens = data['documentosUrl'] ?? [];
          List<dynamic> portfolioImagens = data['portfolio'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- DADOS PESSOAIS / EMPRESA ---
                _buildSecaoTitulo('Dados Principais'),
                if (isLojista) ...[
                  _buildInfoRow('Razão Social', data['razaoSocial'] ?? '-'),
                  _buildInfoRow('CNPJ', data['cnpj'] ?? '-'),
                  _buildInfoRow('Categoria', data['categoria'] ?? '-'),
                  _buildInfoRow('Responsável', '${data['dadosDoResponsavel']?['nome']} ${data['dadosDoResponsavel']?['sobrenome']}'),
                  _buildInfoRow('CPF Responsável', data['dadosDoResponsavel']?['cpf'] ?? '-'),
                ] else ...[
                  // Prestador
                  _buildInfoRow('Nome Completo', '${data['nome']} ${data['sobrenome']}'),
                  _buildInfoRow('CPF', data['cpf'] ?? '-'),
                  _buildInfoRow('Profissão', data['areaAtuacao'] ?? '-'),
                  _buildInfoRow('Preço Médio', 'R\$ ${data['faixaPrecos']}'),
                  _buildInfoRow('Descrição', data['descricaoServicos'] ?? '-'),
                ],
                _buildInfoRow(
                    'Email',
                    isLojista
                        ? (data['dadosDoResponsavel']?['email'] ?? '-')
                        : (data['email'] ?? '-')
                ),
                _buildInfoRow('Telefone', isLojista ? data['telefoneComercial'] : data['telefone']),

                // --- ENDEREÇO ---
                _buildSecaoTitulo('Localização'),
                if (isLojista && data['endereco'] != null) ...[
                  _buildInfoRow('Endereço', '${data['endereco']['rua']}, ${data['endereco']['numero']} - ${data['endereco']['bairro']}'),
                  _buildInfoRow('Cidade/UF', '${data['endereco']['bairro']} - ${data['endereco']['estado']}'), // Ajuste conforme seu modelo
                ] else if (!isLojista) ...[
                  // Prestador (Área de atendimento é lista ou string)
                  _buildInfoRow('Atende em', (data['areaAtendimento'] is List)
                      ? (data['areaAtendimento'] as List).join(', ')
                      : data['areaAtendimento'].toString()),
                ],

                // --- DOCUMENTOS ---
                _buildSecaoTitulo('Documentos Anexados'),
                if (docsImagens.isEmpty)
                  const Text('Nenhum documento enviado.', style: TextStyle(color: Colors.red)),

                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: docsImagens.length,
                    itemBuilder: (ctx, i) => _buildImagemBase64(docsImagens[i]),
                  ),
                ),

                // --- PORTFÓLIO (Só prestador tem geralmente, mas se lojista tiver, mostra) ---
                if (portfolioImagens.isNotEmpty) ...[
                  _buildSecaoTitulo('Portfólio / Fotos'),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: portfolioImagens.length,
                      itemBuilder: (ctx, i) => _buildImagemBase64(portfolioImagens[i]),
                    ),
                  ),
                ],

                const SizedBox(height: 100), // Espaço para os botões flutuantes não tamparem o fim
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _mostrarDialogoRejeicao,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('REJEITAR'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _aprovarCadastro,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('VALIDAR CADASTRO'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}