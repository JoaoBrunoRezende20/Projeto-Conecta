import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/cupom_util.dart';

class CupomRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Retorna stream com os cupons criados pelo lojista
  Stream<QuerySnapshot> getCuponsPorLojista(String lojistaId) {
    return _firestore
        .collection('cupons')
        .where('lojistaId', isEqualTo: lojistaId)
        .snapshots();
  }

  /// Cria um novo cupom no Firestore garantindo que não haja cupom ativo com o mesmo código em nenhuma loja
  Future<void> criarCupom(Map<String, dynamic> dados) async {
    final codigo = (dados['codigo'] ?? '').toString().trim().toUpperCase();
    if (codigo.isEmpty) {
      throw Exception('O código do cupom não pode ser vazio.');
    }

    final bool ativo = dados['ativo'] ?? true;

    // 1. Bloqueia criação de cupom ativo se a data de validade já expirou
    if (ativo && dados['dataValidade'] != null) {
      if (CupomUtil.isExpirado(dados['dataValidade'])) {
        final dataStr = CupomUtil.formatarDataCompleta(dados['dataValidade']);
        throw Exception(
          'Não é possível criar um cupom ativo com data de validade ($dataStr) que já passou. Escolha uma data futura ou salve o cupom como inativo.',
        );
      }
    }

    // 2. Verifica se já existe qualquer cupom ativo com o mesmo código no sistema
    if (ativo) {
      final queryExistente = await _firestore
          .collection('cupons')
          .where('codigo', isEqualTo: codigo)
          .where('ativo', isEqualTo: true)
          .get();

      // Filtra apenas os que realmente não estão expirados
      final ativosNaoExpirados = queryExistente.docs.where((doc) {
        final docData = doc.data();
        return !CupomUtil.isExpirado(docData['dataValidade']);
      }).toList();

      if (ativosNaoExpirados.isNotEmpty) {
        throw Exception(
          'Já existe um cupom ativo com o código "$codigo". Escolha outro código promocional.',
        );
      }
    }

    final Map<String, dynamic> cupomData = {
      ...dados,
      'codigo': codigo,
      'dataCriacao': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('cupons').add(cupomData);
  }

  /// Atualiza os dados de um cupom existente
  Future<void> atualizarCupom(String id, Map<String, dynamic> dados) async {
    final codigo = (dados['codigo'] ?? '').toString().trim().toUpperCase();
    final bool ativo = dados['ativo'] ?? true;

    // 1. Bloqueia salvar como ativo se a data de validade já expirou
    if (ativo && dados['dataValidade'] != null) {
      if (CupomUtil.isExpirado(dados['dataValidade'])) {
        final dataStr = CupomUtil.formatarDataCompleta(dados['dataValidade']);
        throw Exception(
          'Não é possível salvar este cupom como ativo pois sua validade ($dataStr) já expirou. Escolha uma data futura.',
        );
      }
    }

    // 2. Unicidade global
    if (ativo && codigo.isNotEmpty) {
      final queryExistente = await _firestore
          .collection('cupons')
          .where('codigo', isEqualTo: codigo)
          .where('ativo', isEqualTo: true)
          .get();

      final outrosAtivos = queryExistente.docs.where((doc) {
        if (doc.id == id) return false;
        final docData = doc.data();
        return !CupomUtil.isExpirado(docData['dataValidade']);
      }).toList();

      if (outrosAtivos.isNotEmpty) {
        throw Exception(
          'Já existe outro cupom ativo com o código "$codigo". Escolha outro código promocional.',
        );
      }
    }

    if (codigo.isNotEmpty) {
      dados['codigo'] = codigo;
    }
    await _firestore.collection('cupons').doc(id).update(dados);
  }

  /// Ativa ou desativa um cupom validando se a data de validade não expirou e se já há outro ativo com o mesmo código
  Future<void> alternarStatusCupom(String id, bool ativo) async {
    if (ativo) {
      final docAtual = await _firestore.collection('cupons').doc(id).get();
      if (docAtual.exists) {
        final data = docAtual.data();
        final codigo = (data?['codigo'] ?? '').toString().trim().toUpperCase();
        final dataValidade = data?['dataValidade'];

        // 1. Não permite ativar cupom cuja data de validade já expirou
        if (dataValidade != null && CupomUtil.isExpirado(dataValidade)) {
          final dataStr = CupomUtil.formatarDataCompleta(dataValidade);
          throw Exception(
            'Não é possível ativar este cupom: a data de validade ($dataStr) já passou. Edite o cupom e defina uma nova data para poder ativá-lo.',
          );
        }

        // 2. Não permite ativar se já existe outro ativo com mesmo código
        if (codigo.isNotEmpty) {
          final queryExistente = await _firestore
              .collection('cupons')
              .where('codigo', isEqualTo: codigo)
              .where('ativo', isEqualTo: true)
              .get();

          final outrosAtivos = queryExistente.docs.where((doc) {
            if (doc.id == id) return false;
            final docData = doc.data();
            return !CupomUtil.isExpirado(docData['dataValidade']);
          }).toList();

          if (outrosAtivos.isNotEmpty) {
            throw Exception(
              'Não é possível ativar: já existe outro cupom ativo com o código "$codigo".',
            );
          }
        }
      }
    }

    await _firestore.collection('cupons').doc(id).update({'ativo': ativo});
  }

  /// Exclui um cupom
  Future<void> deletarCupom(String id) async {
    await _firestore.collection('cupons').doc(id).delete();
  }

  /// Valida o cupom para o checkout com mensagens de erro precisas para cada cenário e desativação automática de expirados
  Future<Map<String, dynamic>?> validarCupom(
    String codigo,
    double valorCompra, {
    String? lojistaId,
  }) async {
    final codigoLimpo = codigo.trim().toUpperCase();
    if (codigoLimpo.isEmpty) {
      throw Exception('Informe o código do cupom.');
    }

    // Busca o documento do cupom pelo código
    final querySnapshot = await _firestore
        .collection('cupons')
        .where('codigo', isEqualTo: codigoLimpo)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Cupom não encontrado. Verifique o código digitado e tente novamente.');
    }

    final docRef = querySnapshot.docs.first;
    final data = docRef.data();

    // 1. Validação de data de validade (expiração)
    if (data['dataValidade'] != null && CupomUtil.isExpirado(data['dataValidade'])) {
      // Se expirou, garante desativação automática no Firestore
      if (data['ativo'] == true) {
        try {
          await _firestore.collection('cupons').doc(docRef.id).update({'ativo': false});
        } catch (_) {}
      }
      final dataStr = CupomUtil.formatarDataCompleta(data['dataValidade']);
      throw Exception('Este cupom expirou em $dataStr e não é mais válido.');
    }

    // 2. Validação de status ativo
    final bool ativo = data['ativo'] ?? false;
    if (!ativo) {
      throw Exception('Este cupom está desativado no momento.');
    }

    // 3. Validação de Lojista (se o cupom for exclusivo de uma loja)
    final cupomLojistaId = data['lojistaId'] as String?;
    if (cupomLojistaId != null &&
        cupomLojistaId.isNotEmpty &&
        lojistaId != null &&
        lojistaId.isNotEmpty) {
      if (cupomLojistaId != lojistaId) {
        throw Exception('Este cupom não é válido para os produtos desta loja.');
      }
    }

    // 4. Validação de valor mínimo de compra
    final double valorMinimo = ((data['valorMinimo'] ?? 0.0) as num).toDouble();
    if (valorCompra < valorMinimo) {
      throw Exception(
        'O valor mínimo de compra para este cupom é R\$ ${valorMinimo.toStringAsFixed(2).replaceAll('.', ',')}.',
      );
    }

    // Identificação do tipo de desconto (porcentagem ou valor)
    final String tipoDesconto = (data['tipoDesconto'] ?? 'valor').toString();
    final double valorDesconto = ((data['valorDesconto'] ?? data['desconto'] ?? 0.0) as num).toDouble();

    // Cálculo exato do desconto
    final double descontoCalculado = CupomUtil.calcularDesconto(
      tipoDesconto: tipoDesconto,
      valorDesconto: valorDesconto,
      valorCompra: valorCompra,
    );

    return {
      'id': docRef.id,
      'codigo': data['codigo'],
      'tipoDesconto': tipoDesconto,
      'valorDesconto': valorDesconto,
      'desconto': descontoCalculado, // Valor em R$ deduzido
      'descontoCalculado': descontoCalculado,
      'valorMinimo': valorMinimo,
      'lojistaId': cupomLojistaId,
    };
  }
}
