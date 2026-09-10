import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_nosso/telas/perfil/tela_perfil.dart';
import 'package:flutter/material.dart';
import '../utils/auth_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../telas/suporte/tela_faq.dart';
import '../telas/suporte/tela_suporte_chamado.dart';
import '../telas/perfil/tela_notificacoes.dart';
import '../telas/cliente/tela_historico_pedidos.dart';
import '../utils/usuario_util.dart';

import '../telas/lojista/tela_historico_pedidos_lojista.dart';
import '../telas/lojista/tela_cupons_lojista.dart';
import '../telas/cliente/tela_pedidos_pendentes_cliente.dart';
import '../telas/perfil/tela_planos_anuncios.dart';

class MenuLateral extends StatelessWidget {
  final String nomeUsuario;
  final String? urlFotoPerfil;
  final bool isVisitante;
  final String colecaoUsuario;

  const MenuLateral({
    super.key,
    required this.nomeUsuario,
    this.urlFotoPerfil,
    this.isVisitante = false,
    this.colecaoUsuario = 'usuarioComum',
  });



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
                            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => AuthWrapper(),
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
            // 1. CABEÇALHO (FIXO NO TOPO COM DADOS DINÂMICOS DO FIRESTORE)
            Builder(
              builder: (context) {
                final user = FirebaseAuth.instance.currentUser;
                if (isVisitante || user == null) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    color: Colors.grey.shade300,
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade400,
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 28),
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
                  );
                }

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(colecaoUsuario)
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String nomeExibido = nomeUsuario;
                    String? fotoUrlFinal = urlFotoPerfil;

                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null) {
                        nomeExibido = data['razaoSocial'] ??
                            data['nomeFantasia'] ??
                            data['nome'] ??
                            data['nomeCompleto'] ??
                            nomeUsuario;
                        fotoUrlFinal = (data['fotoPerfilUrl'] ??
                                data['logoUrl'] ??
                                data['imagemUrl'])
                            ?.toString() ??
                            urlFotoPerfil;
                      }
                    }

                    final bool isLojistaOuPrestador =
                        colecaoUsuario == 'lojistas' ||
                        colecaoUsuario == 'prestadorServicos';
                    final bool temFoto = isLojistaOuPrestador &&
                        fotoUrlFinal != null &&
                        fotoUrlFinal.isNotEmpty;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      color: Colors.grey.shade300,
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade400,
                              border: Border.all(
                                color: temFoto
                                    ? Colors.deepPurple
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: temFoto
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: UsuarioUtil.buildImageWidget(
                                      fotoUrlFinal,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              nomeExibido,
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
                    );
                  },
                );
              },
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
                      leading: const Icon(Icons.notifications_none),
                      title: const Text("Notificações"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TelaNotificacoes(colecaoUsuario: colecaoUsuario),
                          ),
                        );
                      },
                    ),
                    if (colecaoUsuario == 'usuarioComum') ...[
                      ListTile(
                        leading: const Icon(Icons.pending_actions),
                        title: const Text("Pedidos Pendentes"),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TelaPedidosPendentesCliente(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: const Text("Histórico de pedidos"),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TelaHistoricoPedidos(),
                            ),
                          );
                        },
                      ),

                    ],

                    if (colecaoUsuario == 'lojistas') ...[
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: const Text("Histórico de pedidos"),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TelaHistoricoPedidosLojista(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.discount_outlined, color: Colors.deepPurple),
                        title: const Text("Cupons de Desconto"),
                        onTap: () {
                          Navigator.pop(context);
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TelaCuponsLojista(lojistaId: uid),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                    if (colecaoUsuario == 'lojistas' || colecaoUsuario == 'prestadorServicos') ...[
                      ListTile(
                        leading: const Icon(Icons.campaign, color: Colors.orange),
                        title: const Text(
                          "Destacar meu Negócio",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TelaPlanosAnuncios(),
                            ),
                          );
                        },
                      ),
                    ],
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
              onTap: () {
                Navigator.pop(context); // Fecha o menu lateral primeiro
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaFaq()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text("Abrir um Chamado"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TelaSuporteChamado(isVisitante: isVisitante),
                  ),
                );
              },
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
                    FirebaseAuth.instance.signOut();
                    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => AuthWrapper()),
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





