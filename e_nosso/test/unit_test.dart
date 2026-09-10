import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_nosso/utils/suporte_config.dart';
import 'package:e_nosso/utils/carrinho_util.dart';
import 'package:e_nosso/utils/cupom_util.dart';
import 'package:e_nosso/utils/usuario_util.dart';
import 'package:e_nosso/services/carrinho_service.dart';
import 'package:e_nosso/telas/lojista/tela_inicial_lojista.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cupom & Regras de Desconto Tests', () {
    test('Calcula desconto por porcentagem corretamente', () {
      // 10% de R$ 100,00 = R$ 10,00
      final desc1 = CupomUtil.calcularDesconto(
        tipoDesconto: 'porcentagem',
        valorDesconto: 10.0,
        valorCompra: 100.0,
      );
      expect(desc1, equals(10.0));

      // 25% de R$ 80,00 = R$ 20,00
      final desc2 = CupomUtil.calcularDesconto(
        tipoDesconto: 'porcentagem',
        valorDesconto: 25.0,
        valorCompra: 80.0,
      );
      expect(desc2, equals(20.0));

      // 15.5% de R$ 200,00 = R$ 31,00
      final desc3 = CupomUtil.calcularDesconto(
        tipoDesconto: 'porcentagem',
        valorDesconto: 15.5,
        valorCompra: 200.0,
      );
      expect(desc3, equals(31.0));
    });

    test('Calcula desconto por valor fixo corretamente', () {
      // R$ 15,00 em compra de R$ 50,00 = R$ 15,00
      final desc1 = CupomUtil.calcularDesconto(
        tipoDesconto: 'valor',
        valorDesconto: 15.0,
        valorCompra: 50.0,
      );
      expect(desc1, equals(15.0));

      // R$ 30,00 em compra de R$ 120,50 = R$ 30,00
      final desc2 = CupomUtil.calcularDesconto(
        tipoDesconto: 'valor',
        valorDesconto: 30.0,
        valorCompra: 120.5,
      );
      expect(desc2, equals(30.0));
    });

    test('Desconto nunca ultrapassa o valor total da compra (clamp)', () {
      // Cupom de R$ 100,00 em compra de R$ 40,00 -> Desconto limitado a R$ 40,00
      final descFixo = CupomUtil.calcularDesconto(
        tipoDesconto: 'valor',
        valorDesconto: 100.0,
        valorCompra: 40.0,
      );
      expect(descFixo, equals(40.0));

      // 150% de R$ 50,00 -> Desconto limitado a R$ 50,00
      final descPorcentagem = CupomUtil.calcularDesconto(
        tipoDesconto: 'porcentagem',
        valorDesconto: 150.0,
        valorCompra: 50.0,
      );
      expect(descPorcentagem, equals(50.0));
    });

    test('Valores zerados ou negativos retornam desconto 0', () {
      expect(
        CupomUtil.calcularDesconto(
          tipoDesconto: 'porcentagem',
          valorDesconto: 0,
          valorCompra: 100,
        ),
        equals(0.0),
      );

      expect(
        CupomUtil.calcularDesconto(
          tipoDesconto: 'valor',
          valorDesconto: 10,
          valorCompra: 0,
        ),
        equals(0.0),
      );
    });

    test('Formata textos de desconto corretamente para o usuário', () {
      expect(CupomUtil.formatarTextoDesconto('porcentagem', 10.0), equals('10% OFF'));
      expect(CupomUtil.formatarTextoDesconto('porcentagem', 12.5), equals('12,5% OFF'));
      expect(CupomUtil.formatarTextoDesconto('valor', 15.0), equals('R\$ 15,00 OFF'));
      expect(CupomUtil.formatarTextoDesconto('valor', 7.5), equals('R\$ 7,50 OFF'));
    });

    test('Verifica expiração de cupom por data corretamente', () {
      // Cupom sem data de validade -> nunca expira
      expect(CupomUtil.isExpirado(null), isFalse);

      // Data de ontem -> expirado
      final ontem = DateTime.now().subtract(const Duration(days: 1));
      expect(CupomUtil.isExpirado(ontem), isTrue);

      // Data de 30 dias atrás -> expirado
      final passado = DateTime.now().subtract(const Duration(days: 30));
      expect(CupomUtil.isExpirado(passado), isTrue);

      // Data de amanhã -> NÃO expirado
      final amanha = DateTime.now().add(const Duration(days: 1));
      expect(CupomUtil.isExpirado(amanha), isFalse);

      // Data de hoje (válido até 23:59:59 de hoje) -> NÃO expirado
      final hoje = DateTime.now();
      expect(CupomUtil.isExpirado(DateTime(hoje.year, hoje.month, hoje.day)), isFalse);
    });
  });

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

  group('UsuarioUtil & Imagens Profile/Logo Tests', () {
    test('Obtém nome de lojista e prestador corretamente', () {
      final lojistaMap = {'razaoSocial': 'Padaria Pão Dourado', 'tipo': 'lojista'};
      expect(UsuarioUtil.getNomeCompleto(lojistaMap, tipo: 'lojista'), equals('Padaria Pão Dourado'));

      final prestadorMap = {'nome': 'Carlos', 'sobrenome': 'Silva', 'tipo': 'prestador'};
      expect(UsuarioUtil.getNomeCompleto(prestadorMap, tipo: 'prestador'), equals('Carlos Silva'));
    });

    test('Decodifica Base64 com segurança mesmo com data URI prefix', () {
      // "hello world" em Base64 é "aGVsbG8gd29ybGQ="
      const dataUri = 'data:image/jpeg;base64,aGVsbG8gd29ybGQ=';
      final bytes = UsuarioUtil.decodificarBase64(dataUri);
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes), equals('hello world'));
    });
  });
}

