import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AppFormatadores {
  // --- MÁSCARAS (Geram novas instâncias para evitar conflitos entre telas) ---

  // CPF: 000.000.000-00
  static MaskTextInputFormatter get maskCPF => MaskTextInputFormatter(
    mask: "###.###.###-##",
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // CNPJ: 00.000.000/0001-00
  static MaskTextInputFormatter get maskCNPJ => MaskTextInputFormatter(
    mask: "##.###.###/####-##",
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // Telefone: (00) 90000-0000
  static MaskTextInputFormatter get maskTelefone => MaskTextInputFormatter(
    mask: "(##) #####-####",
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // CEP: 00000-000
  static MaskTextInputFormatter get maskCEP => MaskTextInputFormatter(
    mask: "#####-###",
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // --- VALIDADORES DE INTEGRIDADE (Garantem a quantidade exata de caracteres) ---

  static String? validarCPF(String? value) {
    if (value == null || value.isEmpty) return "Campo obrigatório";
    if (value.length < 14) return "CPF incompleto";
    return null;
  }

  static String? validarCNPJ(String? value) {
    if (value == null || value.isEmpty) return "Campo obrigatório";
    if (value.length < 18) return "CNPJ incompleto";
    return null;
  }

  static String? validarTelefone(String? value) {
    if (value == null || value.isEmpty) return "Campo obrigatório";
    if (value.length < 15) return "Telefone incompleto";
    return null;
  }

  static String? validarCEP(String? value) {
    if (value == null || value.isEmpty) return "Campo obrigatório";
    if (value.length < 9) return "CEP incompleto";
    return null;
  }
}
