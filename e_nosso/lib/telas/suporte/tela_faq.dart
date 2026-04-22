import 'package:flutter/material.dart';

class TelaFaq extends StatelessWidget {
  const TelaFaq({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Dúvidas Frequentes', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "Como podemos ajudar?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Encontre rapidamente respostas para as dúvidas mais comuns da plataforma.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // --- CATEGORIA: GERAL ---
          _buildSecaoTitulo('Conta e Cadastro'),
          _buildFaqItem(
            'Como recupero a minha senha?',
            'Na tela de login, clique em "Esqueci a minha senha" e siga as instruções enviadas para o seu e-mail de registo.',
          ),
          _buildFaqItem(
            'Porque o meu perfil está "Em Análise"?',
            'Para garantir a segurança de todos, os cadastros de Lojistas e Prestadores de Serviço passam por uma verificação manual da nossa equipa de administração. Assim que aprovado, o seu acesso é liberado instantaneamente.',
          ),

          // --- CATEGORIA: CLIENTES ---
          _buildSecaoTitulo('Para Clientes'),
          _buildFaqItem(
            'Como funcionam as formas de pagamento?',
            'O pagamento é combinado diretamente com o lojista no momento da entrega (Dinheiro, Pix ou Cartão). Pode solicitar troco no momento da finalização do pedido no aplicativo.',
          ),
          _buildFaqItem(
            'Para onde vão os itens do meu carrinho?',
            'Os itens ficam salvos no seu aplicativo. Se fechar o app e voltar mais tarde, o seu carrinho continuará lá, a menos que decida esvaziá-lo ou finalizar a compra.',
          ),

          // --- CATEGORIA: LOJISTAS ---
          _buildSecaoTitulo('Para Lojistas'),
          _buildFaqItem(
            'Como adiciono ou edito produtos?',
            'Na aba "Produtos" da sua tela inicial, clique no botão "+" verde para adicionar. Para editar o estoque, use os botões de "+" e "-" diretamente na lista.',
          ),
          _buildFaqItem(
            'Como encontro um profissional para a minha loja?',
            'Basta aceder à aba "Serviços" no seu painel. Lá encontrará o nosso catálogo de profissionais verificados, como eletricistas, técnicos e pintores, com o respetivo contacto.',
          ),

          // --- CATEGORIA: PRESTADORES ---
          _buildSecaoTitulo('Para Prestadores de Serviço'),
          _buildFaqItem(
            'Como serei contactado pelos clientes?',
            'O seu perfil (com as suas especialidades e telefone) fica disponível no nosso "Catálogo de Serviços". Os lojistas e clientes interessados entrarão em contacto direto consigo via telefone ou WhatsApp.',
          ),
          _buildFaqItem(
            'Preciso anexar o Alvará ou Registo Profissional?',
            'Sim! Se a sua profissão é regulamentada (ex: CREA, CRM) ou se preencheu o campo de CNPJ, o anexo do documento é obrigatório para a aprovação do seu perfil.',
          ),

          const SizedBox(height: 40),
          
          // Contato Suporte Direto
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.support_agent, size: 40, color: Colors.blue),
                const SizedBox(height: 12),
                const Text("Ainda com dúvidas?", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  "Se não encontrou a resposta que procurava, entre em contacto com o nosso suporte técnico.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    // Lógica futura para abrir WhatsApp ou E-mail de suporte
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Em breve: Redirecionamento para o WhatsApp de suporte.')),
                    );
                  },
                  child: const Text("Falar com o Suporte"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSecaoTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildFaqItem(String pergunta, String resposta) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(
          pergunta,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                resposta,
                style: TextStyle(color: Colors.grey.shade700, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}