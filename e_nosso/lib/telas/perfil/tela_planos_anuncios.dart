import 'package:flutter/material.dart';

class TelaPlanosAnuncios extends StatelessWidget {
  const TelaPlanosAnuncios({super.key});

  void _assinarPlano(BuildContext context, String nomePlano) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("O plano $nomePlano estará disponível em breve!"),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Destacar meu Negócio",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Escolha o plano ideal para destacar seus serviços e alcançar mais clientes!",
              style: TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            _buildPlanoCard(
              context: context,
              titulo: "Plano Básico",
              preco: "Grátis",
              icone: Icons.list_alt,
              corDestaque: Colors.blueGrey,
              beneficios: [
                "Apareça no Menu Lateral",
                "Visibilidade padrão nas buscas",
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildPlanoCard(
              context: context,
              titulo: "Plano Destaque",
              preco: "R\$ 19,90 / mês",
              icone: Icons.star_border,
              corDestaque: Colors.orange,
              beneficios: [
                "Apareça na Página Inicial",
                "Destaque nas buscas de serviço",
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildPlanoCard(
              context: context,
              titulo: "Plano Premium",
              preco: "R\$ 39,90 / mês",
              icone: Icons.diamond_outlined,
              corDestaque: Colors.purple,
              beneficios: [
                "Apareça na Página Inicial",
                "Apareça no Menu Lateral",
                "Selo de Parceiro Premium",
                "Maior prioridade nas buscas",
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanoCard({
    required BuildContext context,
    required String titulo,
    required String preco,
    required IconData icone,
    required Color corDestaque,
    required List<String> beneficios,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corDestaque.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: corDestaque.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, color: corDestaque, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      preco,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: corDestaque,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...beneficios.map((beneficio) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: corDestaque, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    beneficio,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _assinarPlano(context, titulo),
              style: ElevatedButton.styleFrom(
                backgroundColor: corDestaque,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Assinar",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
