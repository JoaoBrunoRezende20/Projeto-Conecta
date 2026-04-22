import 'package:e_nosso/telas/perfil/tela_perfil.dart';
import 'package:e_nosso/telas/auth/tela_tipo_usuario.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MenuLateral extends StatelessWidget {
  final String nomeUsuario;
  final String? urlFotoPerfil;
  final bool isVisitante;

  const MenuLateral({
    super.key,
    required this.nomeUsuario,
    this.urlFotoPerfil,
    this.isVisitante = false,
  });

  void _mostrarAvisoDesenvolvimento(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Esta funcionalidade estará disponível em breve!"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmarSaida(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Deseja sair da conta?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TelaTipoUsuario(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text(
                        "SAIR",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "CANCELAR",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280,
      child: SafeArea(
        child: Column(
          children: [
            // 1. CABEÇALHO (FIXO NO TOPO)
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: Colors.grey.shade300,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: (!isVisitante && urlFotoPerfil != null)
                        ? NetworkImage(urlFotoPerfil!)
                        : null,
                    child: isVisitante ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isVisitante ? "Visitante" : nomeUsuario,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 2. CONTEÚDO SCROLLABLE (SÓ OPÇÕES DE PERFIL)
            Expanded(
              child: ListView(
                children: [
                  if (!isVisitante) ...[
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text("Editar perfil"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditarPerfilPage(),
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
                      title: const Text("Histórico de pedidos"),
                      onTap: () => _mostrarAvisoDesenvolvimento(context),
                    ),
                  ],
                ],
              ),
            ),

            // 3. SEÇÃO DE AJUDA (FIXA NA PARTE DE BAIXO)
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Ajuda",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
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

            // 4. BOTÃO DE SAIR/ENTRAR (RODAPÉ)
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                isVisitante ? Icons.login : Icons.logout,
                color: isVisitante ? Colors.blue : Colors.red,
              ),
              title: Text(
                isVisitante ? "Entrar / Cadastrar" : "Sair",
                style: TextStyle(
                  color: isVisitante ? Colors.blue : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                if (isVisitante) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const TelaTipoUsuario()),
                    (route) => false,
                  );
                } else {
                  _confirmarSaida(context);
                }
              },
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
