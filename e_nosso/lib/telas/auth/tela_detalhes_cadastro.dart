import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart'; // Certifique-se que adicionou 'gal' no pubspec.yaml
import '../../utils/usuario_util.dart';

class TelaDetalhesCadastro extends StatefulWidget {
  final String usuarioId;
  final String colecao; // 'lojistas' ou 'prestadorServicos'
  final String nomeUsuario;

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

  // --- LÓGICA DE NOTIFICAÇÃO ---
  Future<void> _enviarNotificacaoUsuario({
    required String titulo,
    required String mensagem,
    required String tipo,
  }) async {
    await FirebaseFirestore.instance
        .collection(widget.colecao)
        .doc(widget.usuarioId)
        .collection('notificacoes')
        .add({
          'titulo': titulo,
          'mensagem': mensagem,
          'tipo': tipo,
          'lida': false,
          'data': FieldValue.serverTimestamp(),
        });
  }

  // --- LÓGICA DE SALVAR NA GALERIA (CORRIGIDA COM GAL) ---
  Future<void> _baixarImagem(String base64String) async {
    try {
      Uint8List bytes = UsuarioUtil.decodificarBase64(base64String);

      // Salva usando a biblioteca 'gal'
      await Gal.putImageBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagem salva na Galeria!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on GalException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de permissão ou acesso: ${e.type.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- LÓGICA DE APAGAR UMA IMAGEM ESPECÍFICA ---
  Future<void> _apagarImagemEspecifica(
    String campo,
    String base64String,
  ) async {
    bool confirmar =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Apagar Imagem?'),
            content: const Text(
              'Essa imagem será removida permanentemente do banco de dados para liberar espaço. Certifique-se de ter baixado antes.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Apagar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmar) return;

    try {
      await FirebaseFirestore.instance
          .collection(widget.colecao)
          .doc(widget.usuarioId)
          .update({
            campo: FieldValue.arrayRemove([base64String]),
          });
      if (mounted) {
        Navigator.pop(context); // Fecha o dialog da imagem
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagem removida do banco.')),
        );
      }
    } catch (e) {
      debugPrint('Erro ao apagar imagem: $e');
    }
  }

  // --- VISUALIZADOR TELA CHEIA ---
  void _verImagemTelaCheia(String base64String, String campoOrigem) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                child: Image.memory(
                  UsuarioUtil.decodificarBase64(base64String),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 40,
              right: 20,
              left: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _baixarImagem(base64String),
                    icon: const Icon(Icons.download),
                    label: const Text('Baixar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _apagarImagemEspecifica(campoOrigem, base64String),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Apagar do Banco'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- APROVAÇÃO E REJEIÇÃO ---
  void _mostrarConfirmacaoDecisao(bool aprovar) {
    final justificativaController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(aprovar ? 'Aprovar Cadastro?' : 'Rejeitar Cadastro?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ ATENÇÃO: Ao confirmar, todas as imagens anexadas (Documentos e Portfólio) serão APAGADAS do banco para economizar espaço.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            if (!aprovar)
              TextField(
                controller: justificativaController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Motivo da rejeição (Obrigatório)',
                  border: OutlineInputBorder(),
                ),
              ),
            if (aprovar) const Text('O usuário receberá acesso imediato.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: aprovar ? Colors.green : Colors.red,
            ),
            onPressed: () {
              if (!aprovar && justificativaController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Justificativa necessária.')),
                );
                return;
              }
              Navigator.pop(ctx);
              _processarDecisao(aprovar, justificativaController.text);
            },
            child: Text(aprovar ? 'Confirmar Aprovação' : 'Confirmar Rejeição'),
          ),
        ],
      ),
    );
  }

  Future<void> _processarDecisao(bool aprovar, String motivo) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection(widget.colecao)
          .doc(widget.usuarioId)
          .update({
            'statusCadastro': aprovar ? 'aprovado' : 'rejeitado',
            'status': aprovar ? true : false,
            'motivosRejeicao': aprovar ? FieldValue.delete() : motivo,
            'documentosUrl': [],
          });

      await FirebaseFirestore.instance.collection('logsAdministrativos').add({
        'dataHora': FieldValue.serverTimestamp(),
        'administradorUid': _currentUser?.uid,
        'administradorNome': 'Admin',
        'usuarioAfetadoUid': widget.usuarioId,
        'usuarioAfetadoNome': widget.nomeUsuario,
        'acao': aprovar,
        'justificativa': aprovar
            ? 'Cadastro validado. Docs removidos p/ otimização.'
            : motivo,
        'tipoUsuario': widget.colecao,
      });

      await _enviarNotificacaoUsuario(
        titulo: aprovar ? 'Cadastro Aprovado! 🚀' : 'Cadastro Rejeitado',
        mensagem: aprovar
            ? 'Seu cadastro foi validado. Bem-vindo!'
            : 'Houve um problema: $motivo',
        tipo: aprovar ? 'aprovado' : 'rejeitado',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              aprovar ? 'Aprovado e limpo com sucesso!' : 'Rejeitado.',
            ),
            backgroundColor: aprovar ? Colors.green : Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- WIDGETS ---
  Widget _buildImagemBase64(String base64String, String campoOrigem) {
    try {
      return GestureDetector(
        onTap: () => _verImagemTelaCheia(base64String, campoOrigem),
        child: Container(
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
              UsuarioUtil.decodificarBase64(base64String),
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image),
            ),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox(width: 100, child: Center(child: Text('Erro img')));
    }
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

  Widget _buildSecaoTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          const Divider(),
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
        future: FirebaseFirestore.instance
            .collection(widget.colecao)
            .doc(widget.usuarioId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Usuário não encontrado'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final isLojista = widget.colecao == 'lojistas';

          List<dynamic> docsImagens = data['documentosUrl'] ?? [];
          List<dynamic> portfolioImagens = data['portfolio'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSecaoTitulo('Dados Principais'),
                if (isLojista) ...[
                  _buildInfoRow('Razão Social', data['razaoSocial'] ?? '-'),
                  _buildInfoRow('CNPJ', data['cnpj'] ?? '-'),
                  _buildInfoRow(
                    'Responsável',
                    '${data['dadosDoResponsavel']?['nome']}',
                  ),
                ] else ...[
                  _buildInfoRow('Nome', '${data['nome']} ${data['sobrenome']}'),
                  _buildInfoRow('CPF', data['cpf'] ?? '-'),
                  _buildInfoRow('Profissão', data['areaAtuacao'] ?? '-'),
                ],
                _buildInfoRow(
                  'Email',
                  isLojista
                      ? (data['dadosDoResponsavel']?['email'] ?? '-')
                      : (data['email'] ?? '-'),
                ),
                _buildInfoRow(
                  'Telefone',
                  isLojista ? data['telefoneComercial'] : data['telefone'],
                ),

                _buildSecaoTitulo('Documentos Anexados'),
                if (docsImagens.isEmpty)
                  const Text(
                    'Nenhum documento (ou já foram apagados).',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),

                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: docsImagens.length,
                    itemBuilder: (ctx, i) =>
                        _buildImagemBase64(docsImagens[i], 'documentosUrl'),
                  ),
                ),

                if (portfolioImagens.isNotEmpty) ...[
                  _buildSecaoTitulo('Portfólio / Fotos'),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: portfolioImagens.length,
                      itemBuilder: (ctx, i) =>
                          _buildImagemBase64(portfolioImagens[i], 'portfolio'),
                    ),
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => _mostrarConfirmacaoDecisao(false),
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
                onPressed: _isLoading
                    ? null
                    : () => _mostrarConfirmacaoDecisao(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text('VALIDAR CADASTRO'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
