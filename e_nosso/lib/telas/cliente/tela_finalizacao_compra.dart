import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // NOVO: Para salvar no banco
import 'package:firebase_auth/firebase_auth.dart'; // NOVO: Para pegar o ID do cliente
import 'tela_produtos_disponiveis.dart'; // NOVO: Para acessar a variável carrinhoGlobal

class TelaDadosEntrega extends StatefulWidget {
  final double valorTotal;
  const TelaDadosEntrega({super.key, required this.valorTotal});

  @override
  State<TelaDadosEntrega> createState() => _TelaDadosEntregaState();
}

class _TelaDadosEntregaState extends State<TelaDadosEntrega> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para capturar os dados
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _numeroController = TextEditingController();

  String _metodoPagamento = 'Dinheiro';
  bool _precisaTroco = false;
  final _trocoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Finalizar Pedido",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSecaoTitulo(Icons.person, "Seus Dados"),
              const SizedBox(height: 12),
              _buildTextField(
                "Seu Nome",
                _nomeController,
                Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                "Telefone / WhatsApp",
                _telefoneController,
                Icons.phone_android,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 30),
              _buildSecaoTitulo(Icons.location_on, "Endereço de Entrega"),
              const SizedBox(height: 12),
              _buildTextField("Rua / Avenida", _enderecoController, Icons.map),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField("Bairro", _bairroController, null),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: _buildTextField("Nº", _numeroController, null),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              _buildSecaoTitulo(Icons.payment, "Forma de Pagamento"),
              const SizedBox(height: 12),
              _buildOpcoesPagamento(),

              if (_metodoPagamento == 'Dinheiro') _buildCampoTroco(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildResumoEBotaoEnvio(),
    );
  }

  // Widget para os títulos das seções
  Widget _buildSecaoTitulo(IconData icon, String titulo) {
    return Row(
      children: [
        Icon(icon, color: Colors.red, size: 20),
        const SizedBox(width: 8),
        Text(
          titulo.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  // Campos de texto com o estilo que você gostou (bordas arredondadas)
  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData? icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        filled: true,
        fillColor: Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => value!.isEmpty ? "Campo obrigatório" : null,
    );
  }

  Widget _buildOpcoesPagamento() {
    return Column(
      children: ['Dinheiro', 'Cartão (Débito/Crédito)', 'Pix'].map((tipo) {
        return RadioListTile<String>(
          title: Text(tipo),
          value: tipo,
          groupValue: _metodoPagamento,
          activeColor: Colors.red,
          onChanged: (val) => setState(() => _metodoPagamento = val!),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildCampoTroco() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text("Precisa de troco?"),
          value: _precisaTroco,
          activeThumbColor: Colors.red,
          onChanged: (val) => setState(() => _precisaTroco = val),
        ),
        if (_precisaTroco)
          _buildTextField(
            "Troco para quanto?",
            _trocoController,
            Icons.attach_money,
            keyboardType: TextInputType.number,
          ),
      ],
    );
  }

  Widget _buildResumoEBotaoEnvio() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total com entrega:",
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  "R\$ ${widget.valorTotal.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _finalizarPedido();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "CONFIRMAR PEDIDO",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NOVA LÓGICA DE SALVAR NO FIREBASE ---
  Future<void> _finalizarPedido() async {
    // Mostra um círculo de carregamento enquanto salva no banco
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Pega o ID do usuário que está comprando
      final clienteId =
          FirebaseAuth.instance.currentUser?.uid ?? 'cliente_desconhecido';

      // 2. Monta o pacote de dados do pedido
      final pedidoData = {
        'clienteId': clienteId,
        'lojistaId': lojaIdDoCarrinho, // Vem da tela anterior
        'itens': carrinhoGlobal, // Vem da tela anterior
        'valorTotal': widget.valorTotal,
        'status': 'pendente', // pendente, aceito, cancelado, etc.
        'dataCriacao': FieldValue.serverTimestamp(),
        'dadosCliente': {
          'nome': _nomeController.text.trim(),
          'telefone': _telefoneController.text.trim(),
        },
        'dadosEntrega': {
          'endereco': _enderecoController.text.trim(),
          'bairro': _bairroController.text.trim(),
          'numero': _numeroController.text.trim(),
        },
        'pagamento': {
          'metodo': _metodoPagamento,
          'precisaTroco': _precisaTroco,
          'trocoPara': _trocoController.text.trim(),
        },
      };

      // 3. Salva no banco de dados na coleção "pedidos"
      await FirebaseFirestore.instance.collection('pedidos').add(pedidoData);

      // 4. Limpa o carrinho global agora que a compra foi feita
      carrinhoGlobal.clear();
      lojaIdDoCarrinho = null;

      // Fecha a bolinha de carregamento
      if (mounted) Navigator.pop(context);

      // 5. Mostra o aviso de Sucesso
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, // Usuário tem que clicar no OK para sair
          builder: (context) => AlertDialog(
            title: const Text("Sucesso!"),
            content: const Text(
              "Seu pedido foi enviado com sucesso para o lojista.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Volta para o início do aplicativo (Tela inicial do cliente)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Se der erro, fecha o carregamento e avisa
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao salvar o pedido: $e")));
      }
    }
  }
}
