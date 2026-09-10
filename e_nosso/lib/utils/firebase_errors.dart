class FirebaseErrors {
  static String getMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nenhum usuário encontrado para este e-mail.';
      case 'wrong-password':
        return 'Senha incorreta. Tente novamente.';
      case 'invalid-email':
        return 'O endereço de e-mail é inválido.';
      case 'user-disabled':
        return 'O usuário correspondente ao e-mail fornecido foi desativado.';
      case 'too-many-requests':
        return 'Muitas tentativas de login malsucedidas. Tente novamente mais tarde.';
      case 'operation-not-allowed':
        return 'O tipo de conta correspondente a esta credencial não está ativado.';
      case 'email-already-in-use':
        return 'O e-mail fornecido já está em uso por outro usuário.';
      case 'weak-password':
        return 'A senha fornecida é muito fraca.';
      case 'credential-already-in-use':
        return 'Esta credencial já está associada a uma conta de usuário diferente.';
      case 'account-exists-with-different-credential':
        return 'Já existe uma conta com o endereço de e-mail associado a esta credencial.';
      case 'requires-recent-login':
        return 'Esta operação é sensível e requer autenticação recente. Faça login novamente antes de tentar esta solicitação.';
      case 'network-request-failed':
        return 'Falha na conexão de rede. Verifique sua internet.';
      case 'invalid-credential':
        return 'As credenciais de autenticação são inválidas, estão malformadas ou expiraram.';
      default:
        return 'Ocorreu um erro desconhecido. Tente novamente. (Código: \)';
    }
  }
}
