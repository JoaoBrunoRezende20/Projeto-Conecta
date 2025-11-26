import 'package:flutter/material.dart';

class EditarPerfilPage extends StatelessWidget {
  const EditarPerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Editar Perfil"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nome:"),
            TextField(),
            SizedBox(height: 16),
            Text("Área de atuação:"),
            TextField(),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }
}
