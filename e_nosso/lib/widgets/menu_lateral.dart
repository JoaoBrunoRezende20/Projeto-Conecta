import 'package:e_nosso/telas/perfil/tela_perfil.dart';
import 'package:e_nosso/telas/auth/tela_tipo_usuario.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Necessário para o logout real

class MenuLateral extends StatelessWidget {
  final String nomeUsuario;
  final String? urlFotoPerfil;

  const MenuLateral({super.key, required this.nomeUsuario, this.urlFotoPerfil});

  // Função auxiliar para mostrar que a tela ainda não existe
  void _mostrarAvisoDesenvolvimento(BuildContext context) {
    Navigator.pop(context); // Fecha o menu lateral
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Esta funcionalidade estará disponível em breve!"),
        duration: Duration(seconds: 2),
      ),
    );
  }

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
                    onTap: () => _mostrarAvisoDesenvolvimento(context),
                  ),

                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text("Histórico de pedidos e compras"),
                    onTap: () => _mostrarAvisoDesenvolvimento(context),
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
                    onTap: () => _mostrarAvisoDesenvolvimento(context),
                  ),

                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text("Configurações"),
                    onTap: () => _mostrarAvisoDesenvolvimento(context),
                  ),

                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text("Ajuda"),
                    onTap: () => _mostrarAvisoDesenvolvimento(context),
                  ),
                ],
              ),
            ),

            // -----------------------------------------
            // BOTÃO SAIR (PARTE INFERIOR)
            // -----------------------------------------
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Sair", style: TextStyle(color: Colors.red)),
              onTap: () async {
                // 1. Fecha o menu lateral
                Navigator.pop(context);

                // 2. Faz o logout real no Firebase
                await FirebaseAuth.instance.signOut();

                // 3. Limpa todo o histórico de navegação e volta para a escolha de perfil
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const TelaTipoUsuario()),
                    (route) => false,
                  );
                }
              },
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
