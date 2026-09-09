/// Configuração centralizada para suporte e contato com a administração.
class SuporteConfig {
  /// Lista de e-mails dos administradores que recebem chamados e dúvidas.
  /// Novos e-mails podem ser adicionados aqui diretamente.
  static const List<String> emailsAdmin = [
    'taisrodriguesdacosta@gmail.com',
  ];

  /// E-mail principal de destino
  static String get emailPrincipal =>
      emailsAdmin.isNotEmpty ? emailsAdmin.first : 'suporte@conecta.com';

  /// E-mails em cópia (CC), caso haja mais de um administrador configurado
  static List<String> get emailsCopia =>
      emailsAdmin.length > 1 ? emailsAdmin.sublist(1) : [];

  /// Cria a URI do mailto com múltiplos destinatários (To e CC)
  static Uri gerarUriMailto({required String assunto, required String corpo}) {
    final queryParams = <String, String>{
      'subject': assunto,
      'body': corpo,
    };
    if (emailsCopia.isNotEmpty) {
      queryParams['cc'] = emailsCopia.join(',');
    }

    return Uri(
      scheme: 'mailto',
      path: emailPrincipal,
      queryParameters: queryParams,
    );
  }
}
