import 'package:cloud_firestore/cloud_firestore.dart';

class CupomRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> validarCupom(String codigo, double valorCompra) async {
    final querySnapshot = await _firestore
        .collection('cupons')
        .where('codigo', isEqualTo: codigo.toUpperCase())
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Cupom não encontrado.');
    }

    final data = querySnapshot.docs.first.data();

    // Validações
    final bool ativo = data['ativo'] ?? false;
    if (!ativo) {
      throw Exception('Este cupom não está mais ativo.');
    }

    if (data['dataValidade'] != null) {
      final Timestamp validade = data['dataValidade'];
      if (validade.toDate().isBefore(DateTime.now())) {
        throw Exception('Este cupom já expirou.');
      }
    }

    final double valorMinimo = (data['valorMinimo'] ?? 0.0).toDouble();
    if (valorCompra < valorMinimo) {
      throw Exception('O valor mínimo para este cupom é R\$ ${valorMinimo.toStringAsFixed(2).replaceAll('.', ',')}.');
    }

    return {
      'id': querySnapshot.docs.first.id,
      'codigo': data['codigo'],
      'desconto': (data['desconto'] ?? 0.0).toDouble(),
    };
  }
}
