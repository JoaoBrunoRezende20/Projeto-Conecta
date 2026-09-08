import 'package:flutter/material.dart';

/// Modal para inserção obrigatória do motivo de recusa/cancelamento de pedido pelo lojista.
class ModalRecusaPedido extends StatefulWidget {
  const ModalRecusaPedido({super.key});

  /// Método estático utilitário para exibir o modal e obter o motivo preenchido.
  static Future<String?> exibir(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ModalRecusaPedido(),
    );
  }

  @override
  State<ModalRecusaPedido> createState() => _ModalRecusaPedidoState();
}

class _ModalRecusaPedidoState extends State<ModalRecusaPedido> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _motivoController = TextEditingController();

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (_formKey.currentState?.validate() ?? false) {
      final motivo = _motivoController.text.trim();
      Navigator.of(context).pop(motivo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cancel_outlined,
              color: Colors.red.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Recusar Pedido',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Por favor, informe o motivo da recusa. Essa justificativa será enviada diretamente ao cliente.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motivoController,
                maxLines: 4,
                maxLength: 250,
                autofocus: true,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: 'Motivo da recusa *',
                  hintText: 'Ex: Produto esgotado no estoque, loja sem entregador no momento...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.red.shade700, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.red.shade400),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O motivo da recusa é obrigatório.';
                  }
                  if (value.trim().length < 5) {
                    return 'Descreva o motivo com pelo menos 5 caracteres.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            foregroundColor: Colors.grey.shade700,
          ),
          child: const Text(
            'Voltar',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: _confirmar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Confirmar Recusa',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
