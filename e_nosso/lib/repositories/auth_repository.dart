import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Retorna o usuário logado atualmente (pode ser nulo)
  User? get usuarioAtual => _auth.currentUser;

  /// Retorna um Stream para escutar mudanças no estado de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Realiza o login com email e senha
  Future<UserCredential> login(String email, String senha) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: senha,
    );
  }

  /// Realiza o cadastro de um novo usuário com email e senha
  Future<UserCredential> cadastrar(String email, String senha) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );
  }

  /// Envia um e-mail de redefinição de senha
  Future<void> recuperarSenha(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Desloga do aplicativo
  Future<void> sair() async {
    await _auth.signOut();
  }

  /// Envia e-mail de verificação para o usuário atual
  Future<void> enviarEmailVerificacao() async {
    if (_auth.currentUser != null && !_auth.currentUser!.emailVerified) {
      await _auth.currentUser!.sendEmailVerification();
    }
  }
}
