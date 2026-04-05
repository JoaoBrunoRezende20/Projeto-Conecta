import 'package:flutter/material.dart';

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
      decoration: BoxDecoration(
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
                    // Aqui entrará a lógica para salvar no Firebase ou enviar WhatsApp
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

  void _finalizarPedido() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sucesso!"),
        content: const Text("Seu pedido foi enviado com sucesso."),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
