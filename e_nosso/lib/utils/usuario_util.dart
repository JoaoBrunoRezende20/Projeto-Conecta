import 'dart:convert';
import 'dart:typed_data';

class UsuarioUtil {

  /// Recupera o nome completo do usuário de forma consistente
  ///
  /// Parâmetros:
  ///   - dados: Mapa com os dados do usuário
  ///   - tipo: Tipo de usuário ('lojista', 'prestador', 'comum')
  ///   - colecao: Nome da coleção do Firestore
  ///
  /// Retorna o nome formatado ou 'Usuário' se não for encontrado
  static String getNomeCompleto(Map<String, dynamic> dados, {
    String? tipo,
    String? colecao,
  }) {
    // Lojista: prioriza razão social, depois dados do responsável
    if (colecao == 'lojistas' || tipo == 'lojista') {
      return dados['razaoSocial'] ??
             dados['dadosDoResponsavel']?['nome'] ??
             'Lojista';
    }

    // Prestador: nome + sobrenome
    if (colecao == 'prestadorServicos' || tipo == 'prestador') {
      String nome = dados['nome'] ?? '';
      String sobrenome = dados['sobrenome'] ?? '';

      if (nome.isNotEmpty && sobrenome.isNotEmpty) {
        return '$nome $sobrenome';
      } else if (nome.isNotEmpty) {
        return nome;
      } else if (sobrenome.isNotEmpty) {
        return sobrenome;
      } else {
        return 'Prestador';
      }
    }

    // Usuário comum: nome + sobrenome
    if (colecao == 'usuarioComum' || tipo == 'comum') {
      String nome = dados['nome'] ?? '';
      String sobrenome = dados['sobrenome'] ?? '';

      if (nome.isNotEmpty && sobrenome.isNotEmpty) {
        return '$nome $sobrenome';
      } else if (nome.isNotEmpty) {
        return nome;
      } else if (sobrenome.isNotEmpty) {
        return sobrenome;
      } else {
        return 'Usuário';
      }
    }

    // Fallback geral: procura por campos comuns
    return dados['nome'] ??
           dados['razaoSocial'] ??
           dados['dadosDoResponsavel']?['nome'] ??
           'Usuário';
  }

  /// Recupera um nome curto para exibição em listas
  static String getNomeCurto(Map<String, dynamic> dados, {
    String? tipo,
    String? colecao,
  }) {
    String nomeCompleto = getNomeCompleto(dados, tipo: tipo, colecao: colecao);

    // Se for muito longo, retorna apenas o primeiro nome
    if (nomeCompleto.length > 20) {
      List<String> partes = nomeCompleto.split(' ');
      return partes.isNotEmpty ? partes[0] : nomeCompleto;
    }

    return nomeCompleto;
  }

  /// Formata o nome para exibição em cards ou listas
  static String formatarNomeExibicao(String nome) {
    if (nome.length > 25) {
      return '${nome.substring(0, 22)}...';
    }
    return nome;
  }

  /// Verifica se o usuário tem nome válido
  static bool temNomeValido(Map<String, dynamic> dados, {
    String? tipo,
    String? colecao,
  }) {
    String nome = getNomeCompleto(dados, tipo: tipo, colecao: colecao);
    return nome.isNotEmpty && nome != 'Usuário' && nome != 'Lojista' && nome != 'Prestador';
  }

  /// Decodifica com segurança uma string Base64 (limpando cabeçalho, espaços e ajustando padding)
  static Uint8List decodificarBase64(String base64String) {
    try {
      String limpa = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      
      // Remove espaços, quebras de linha e caracteres não-base64 seguros
      limpa = limpa.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
      
      // Ajusta o padding se necessário
      int padding = limpa.length % 4;
      if (padding != 0) {
        limpa += '=' * (4 - padding);
      }
      return base64Decode(limpa);
    } catch (e) {
      throw Exception('Erro ao decodificar Base64: $e');
    }
  }
}