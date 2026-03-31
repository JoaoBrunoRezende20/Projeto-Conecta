import 'package:e_nosso/telas/perfil/tela_perfil.dart';
import 'package:flutter/material.dart';

class MenuLateral extends StatelessWidget {
  final String nomeUsuario;
  final String? urlFotoPerfil;

  const MenuLateral({super.key, required this.nomeUsuario, this.urlFotoPerfil});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------------
            // CABEÇALHO DO MENU
            // -----------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              color: Colors.grey.shade300,
              child: Row(
                children: [
                  // Foto do usuário
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade500,
                    backgroundImage: urlFotoPerfil != null
                        ? NetworkImage(urlFotoPerfil!)
                        : null,
                  ),
                  const SizedBox(width: 10),

                  // Nome
                  Expanded(
                    child: Text(
                      nomeUsuario,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Botão fechar (voltar)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // -----------------------------------------
            // OPÇÕES DO MENU
            // -----------------------------------------
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text("Editar perfil"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditarPerfilPage(),
                        ),
                      );
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.favorite_border),
                    title: const Text("Favoritos"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/favoritos");
                    },
                  ),

                  ListTile(
                    leading: Icon(Icons.edit),
                    title: Text("Editar Perfil"),
                    onTap: () {
                      // TODO: Ir para tela de edição
                    },
                  ), //*******************

                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text("Histórico de pedidos e compras"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/historico");
                    },
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      "Ajuda",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text("Tem dúvidas? Acesse o FAQ"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/faq");
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text("Configurações"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/configuracoes");
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text("Ajuda"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/ajuda");
                    },
                  ),
                ],
              ),
            ),

            // -----------------------------------------
            // BOTÃO SAIR (PARTE INFERIOR)
            // -----------------------------------------
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Sair"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, "/login");
              },
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
