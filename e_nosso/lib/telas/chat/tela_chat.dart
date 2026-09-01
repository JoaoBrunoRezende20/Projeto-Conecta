import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../repositories/chat_repository.dart';

class TelaChat extends StatefulWidget {
  final String conversaId; // Same as pedidoId
  final String tituloChat; // Nome da loja/prestador ou nome do cliente
  final String currentUserId; // ID de quem está logado

  const TelaChat({
    super.key,
    required this.conversaId,
    required this.tituloChat,
    required this.currentUserId,
  });

  @override
  State<TelaChat> createState() => _TelaChatState();
}

class _TelaChatState extends State<TelaChat> {
  final TextEditingController _mensagemController = TextEditingController();
  final ChatRepository _chatRepository = ChatRepository();
  bool _isSending = false;

  void _enviarMensagem() async {
    final texto = _mensagemController.text.trim();
    if (texto.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    await _chatRepository.enviarMensagem(
      pedidoId: widget.conversaId,
      remetenteId: widget.currentUserId,
      texto: texto,
    );

    _mensagemController.clear();
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(widget.tituloChat, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Lista de Mensagens
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatRepository.getMensagens(widget.conversaId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Erro ao carregar chat."));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Nenhuma mensagem ainda.\nEnvie um oi!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final mensagens = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Começa do final (ordem decrescente)
                  padding: const EdgeInsets.all(16),
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final msg = mensagens[index].data() as Map<String, dynamic>;
                    final bool isMe = msg['remetenteId'] == widget.currentUserId;
                    final String texto = msg['texto'] ?? '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green[100] : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            )
                          ],
                        ),
                        child: Text(
                          texto,
                          style: const TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Campo de Digitação
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(color: Colors.white),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mensagemController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Digite sua mensagem...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _enviarMensagem(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.red,
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _enviarMensagem,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
