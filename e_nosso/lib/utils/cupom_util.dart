import 'package:cloud_firestore/cloud_firestore.dart';

class CupomUtil {
  static const List<String> mesesPt = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro'
  ];

  /// Converte qualquer formato de data do Firestore/App para DateTime local
  static DateTime? obterDataValidade(dynamic dataValidade) {
    if (dataValidade == null) return null;

    if (dataValidade is Timestamp) {
      return dataValidade.toDate().toLocal();
    } else if (dataValidade is DateTime) {
      return dataValidade.toLocal();
    } else if (dataValidade is String) {
      final parsed = DateTime.tryParse(dataValidade);
      return parsed?.toLocal();
    }
    return null;
  }

  /// Retorna o nome do mês por extenso (ex: "Setembro", "Outubro")
  static String obterNomeMes(dynamic dataValidade) {
    final dt = obterDataValidade(dataValidade);
    if (dt == null) return "";
    if (dt.month >= 1 && dt.month <= 12) {
      return mesesPt[dt.month - 1];
    }
    return "";
  }

  /// Verifica se uma data de validade já expirou considerando o fim do dia (23:59:59) no horário local
  static bool isExpirado(dynamic dataValidade) {
    if (dataValidade == null) return false;

    final dataLocal = obterDataValidade(dataValidade);
    if (dataLocal == null) return false;

    // O cupom é válido estritamente até as 23:59:59.999 do dia estipulado
    final fimDoDiaValidade = DateTime(
      dataLocal.year,
      dataLocal.month,
      dataLocal.day,
      23,
      59,
      59,
      999,
    );

    return DateTime.now().isAfter(fimDoDiaValidade);
  }

  /// Retorna a data formatada no padrão DD/MM/AAAA (ex: "09/09/2026")
  static String formatarDataPtBr(dynamic dataValidade) {
    final dt = obterDataValidade(dataValidade);
    if (dt == null) return "Sem validade";
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final ano = dt.year.toString();
    return "$dia/$mes/$ano";
  }

  /// Retorna a data formatada no padrão DD/MM/AAAA (ex: "09/09/2026")
  static String formatarDataCompleta(dynamic dataValidade) {
    return formatarDataPtBr(dataValidade);
  }

  /// Calcula o valor absoluto em reais do desconto baseado no tipo ('porcentagem' ou 'valor')
  static double calcularDesconto({
    required String tipoDesconto,
    required double valorDesconto,
    required double valorCompra,
  }) {
    if (valorCompra <= 0 || valorDesconto <= 0) {
      return 0.0;
    }

    double descontoCalculado = 0.0;
    final tipoNormalizado = tipoDesconto.toLowerCase().trim();

    if (tipoNormalizado == 'porcentagem' || tipoNormalizado == '%') {
      // Ex: 10% de R$ 100,00 -> R$ 10,00
      descontoCalculado = valorCompra * (valorDesconto / 100.0);
    } else {
      // Valor fixo em reais
      descontoCalculado = valorDesconto;
    }

    // O desconto nunca pode ultrapassar o valor total da compra
    if (descontoCalculado > valorCompra) {
      descontoCalculado = valorCompra;
    }

    if (descontoCalculado < 0) {
      descontoCalculado = 0.0;
    }

    return double.parse(descontoCalculado.toStringAsFixed(2));
  }

  /// Formata a descrição do desconto para exibição
  static String formatarTextoDesconto(String tipoDesconto, double valorDesconto) {
    final tipoNormalizado = tipoDesconto.toLowerCase().trim();
    if (tipoNormalizado == 'porcentagem' || tipoNormalizado == '%') {
      final valorFormatado = valorDesconto % 1 == 0
          ? valorDesconto.toInt().toString()
          : valorDesconto.toStringAsFixed(1).replaceAll('.', ',');
      return "$valorFormatado% OFF";
    } else {
      return "R\$ ${valorDesconto.toStringAsFixed(2).replaceAll('.', ',')} OFF";
    }
  }
}
