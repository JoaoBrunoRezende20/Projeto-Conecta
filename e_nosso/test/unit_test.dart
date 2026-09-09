import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_nosso/utils/suporte_config.dart';
import 'package:e_nosso/utils/carrinho_util.dart';
import 'package:e_nosso/services/carrinho_service.dart';
import 'package:e_nosso/telas/lojista/tela_inicial_lojista.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SuporteConfig Tests', () {
    test('Verifica e-mail principal configurado', () {
      expect(SuporteConfig.emailPrincipal, equals('taisrodriguesdacosta@gmail.com'));
    });

    test('Gera URI mailto correta com assunto e corpo', () {
      final uri = SuporteConfig.gerarUriMailto(
        assunto: 'Teste Assunto',
        corpo: 'Teste Mensagem',
      );

      expect(uri.scheme, equals('mailto'));
      expect(uri.path, equals('taisrodriguesdacosta@gmail.com'));
      expect(uri.queryParameters['subject'], equals('Teste Assunto'));
      expect(uri.queryParameters['body'], equals('Teste Mensagem'));
    });
  });

  group('Produto Model Tests', () {
    test('Produto serializa e desserializa campo imagem corretamente', () {
      final produtoComImagem = Produto.fromMap({
        'nome': 'Bolo de Chocolate',
        'preco': 25.5,
        'descricao': 'Bolo caseiro',
        'imagem': 'data:image/jpeg;base64,/9j/4AAQSkZJRgABA...',
      }, 'prod_123');

      expect(produtoComImagem.id, equals('prod_123'));
      expect(produtoComImagem.nome, equals('Bolo de Chocolate'));
      expect(produtoComImagem.preco, equals(25.5));
      expect(produtoComImagem.descricao, equals('Bolo caseiro'));
      expect(produtoComImagem.imagem, equals('data:image/jpeg;base64,/9j/4AAQSkZJRgABA...'));

      final map = produtoComImagem.toMap();
      expect(map['imagem'], equals('data:image/jpeg;base64,/9j/4AAQSkZJRgABA...'));
    });

    test('Produto sem imagem atribui null sem quebrar', () {
      final produtoSemImagem = Produto.fromMap({
        'nome': 'Bolo de Cenoura',
        'preco': 20.0,
        'descricao': 'Sem cobertura',
      }, 'prod_456');

      expect(produtoSemImagem.imagem, isNull);
      final map = produtoSemImagem.toMap();
      expect(map['imagem'], isNull);
    });
  });

  group('Carrinho & Persistência Tests (Continuar Comprando)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final carrinhoService = CarrinhoService();
      await carrinhoService.limparCarrinho();
    });

    test('Salva e carrega carrinho via CarrinhoUtil', () async {
      final dadosTeste = {
        'prod_1': {'nome': 'Coxinha', 'preco': 5.0, 'quantidade': 2, 'lojaId': 'loja_a'}
      };

      await CarrinhoUtil.salvarCarrinho(dadosTeste, 'loja_a');
      final carregado = await CarrinhoUtil.carregarCarrinho();

      expect(carregado['carrinho'], isNotEmpty);
      expect(carregado['carrinho']['prod_1']['nome'], equals('Coxinha'));
      expect(carregado['carrinho']['prod_1']['quantidade'], equals(2));
      expect(carregado['lojaId'], equals('loja_a'));
    });

    test('Continuar Comprando: adiciona múltiplos itens sem perder o anterior', () async {
      final carrinho = CarrinhoService();

      // Adiciona primeiro item
      await carrinho.adicionarItem('prod_1', {
        'nome': 'Pão Francês',
        'preco': 1.5,
        'quantidade': 4,
      }, 'loja_padaria');

      expect(carrinho.itens.length, equals(1));
      expect(carrinho.quantidadeTotal, equals(4));
      expect(carrinho.itens['prod_1']!['nome'], equals('Pão Francês'));

      // Simula "Continuar Comprando" e adicionar segundo item
      await carrinho.adicionarItem('prod_2', {
        'nome': 'Café Expresso',
        'preco': 4.0,
        'quantidade': 1,
      }, 'loja_padaria');

      // O produto anterior continua salvo no carrinho!
      expect(carrinho.itens.length, equals(2));
      expect(carrinho.itens.containsKey('prod_1'), isTrue);
      expect(carrinho.itens.containsKey('prod_2'), isTrue);
      expect(carrinho.quantidadeTotal, equals(5));

      // Verifica persistência no SharedPreferences
      final dadosSalvos = await CarrinhoUtil.carregarCarrinho();
      final mapaSalvo = dadosSalvos['carrinho'] as Map<String, dynamic>;
      expect(mapaSalvo.containsKey('prod_1'), isTrue);
      expect(mapaSalvo.containsKey('prod_2'), isTrue);
      expect(mapaSalvo['prod_1']['quantidade'], equals(4));
      expect(mapaSalvo['prod_2']['quantidade'], equals(1));
    });

    test('Incrementar e decrementar itens preserva dados', () async {
      final carrinho = CarrinhoService();

      await carrinho.adicionarItem('prod_1', {
        'nome': 'Suco de Laranja',
        'preco': 8.0,
        'quantidade': 1,
      }, 'loja_lanches');

      // Incrementa
      await carrinho.adicionarItem('prod_1', {'quantidade': 1}, 'loja_lanches');
      expect(carrinho.itens['prod_1']!['quantidade'], equals(2));

      // Decrementa
      await carrinho.decrementarItem('prod_1');
      expect(carrinho.itens['prod_1']!['quantidade'], equals(1));

      // Decrementa até remover
      await carrinho.decrementarItem('prod_1');
      expect(carrinho.isEmpty, isTrue);
    });

    test('Restauração de sessão: inicializar() carrega itens salvos previamente', () async {
      // Grava no SharedPreferences simulando sessão anterior
      await CarrinhoUtil.salvarCarrinho({
        'prod_antigo': {'nome': 'Bolo Salvo', 'preco': 15.0, 'quantidade': 1, 'lojaId': 'loja_x'}
      }, 'loja_x');

      final carrinho = CarrinhoService();
      await carrinho.inicializar(force: true);

      expect(carrinho.isNotEmpty, isTrue);
      expect(carrinho.itens.containsKey('prod_antigo'), isTrue);
      expect(carrinho.itens['prod_antigo']!['nome'], equals('Bolo Salvo'));
      expect(carrinho.lojaId, equals('loja_x'));
    });
  });
}

