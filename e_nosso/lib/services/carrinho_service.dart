import 'package:flutter/material.dart';
import '../utils/carrinho_util.dart';

class CarrinhoService extends ChangeNotifier {
  static final CarrinhoService _instance = CarrinhoService._internal();

  factory CarrinhoService() {
    return _instance;
  }

  CarrinhoService._internal();

  final Map<String, Map<String, dynamic>> _itens = {};
  String? _lojaId;
  bool _inicializado = false;

  Map<String, Map<String, dynamic>> get itens => _itens;
  String? get lojaId => _lojaId;
  bool get isInicializado => _inicializado;
  
  int get quantidadeTotal => _itens.values.fold(
      0, (sum, item) => sum + ((item['quantidade'] ?? 0) as num).toInt());
  
  bool get isEmpty => _itens.isEmpty;
  bool get isNotEmpty => _itens.isNotEmpty;

  Future<void> inicializar({bool force = false}) async {
    if (_inicializado && !force) return;

    final dados = await CarrinhoUtil.carregarCarrinho();
    final Map<String, Map<String, dynamic>>? carrinhoSalvo =
        dados['carrinho'] as Map<String, Map<String, dynamic>>?;

    if (force || _itens.isEmpty) {
      _itens.clear();
      if (carrinhoSalvo != null && carrinhoSalvo.isNotEmpty) {
        _itens.addAll(carrinhoSalvo);
      }
    } else if (carrinhoSalvo != null && carrinhoSalvo.isNotEmpty) {
      // Preserva itens em memória e mescla itens salvos que ainda não existam
      for (final entry in carrinhoSalvo.entries) {
        if (!_itens.containsKey(entry.key)) {
          _itens[entry.key] = Map<String, dynamic>.from(entry.value);
        }
      }
    }

    if (_lojaId == null || _lojaId!.isEmpty) {
      _lojaId = dados['lojaId'] as String?;
    }

    _inicializado = true;
    notifyListeners();
  }

  Future<void> adicionarItem(
      String id, Map<String, dynamic> item, String lojaId) async {
    if (!_inicializado) {
      await inicializar();
    }

    if (_lojaId == null || _lojaId!.isEmpty) {
      _lojaId = lojaId;
    }

    final int qtdParaAdicionar = ((item['quantidade'] ?? 1) as num).toInt();

    if (_itens.containsKey(id)) {
      final int qtdAtual = ((_itens[id]!['quantidade'] ?? 0) as num).toInt();
      _itens[id]!['quantidade'] = qtdAtual + qtdParaAdicionar;
      if (item.containsKey('nome')) _itens[id]!['nome'] = item['nome'];
      if (item.containsKey('preco')) {
        _itens[id]!['preco'] = ((item['preco'] ?? 0.0) as num).toDouble();
      }
      if (item.containsKey('imagem')) _itens[id]!['imagem'] = item['imagem'];
      if (item.containsKey('lojaNome')) {
        _itens[id]!['lojaNome'] = item['lojaNome'];
      }
      if (!_itens[id]!.containsKey('lojaId') ||
          _itens[id]!['lojaId'] == null ||
          _itens[id]!['lojaId'].toString().isEmpty) {
        _itens[id]!['lojaId'] = lojaId;
      }
    } else {
      final novoItem = Map<String, dynamic>.from(item);
      novoItem['quantidade'] = qtdParaAdicionar;
      if (novoItem.containsKey('preco')) {
        novoItem['preco'] = ((novoItem['preco'] ?? 0.0) as num).toDouble();
      }
      if (!novoItem.containsKey('lojaId') ||
          novoItem['lojaId'] == null ||
          novoItem['lojaId'].toString().isEmpty) {
        novoItem['lojaId'] = lojaId;
      }
      _itens[id] = novoItem;
    }

    notifyListeners();
    await CarrinhoUtil.salvarCarrinho(_itens, _lojaId);
  }

  Future<void> removerItem(String id) async {
    if (!_inicializado) {
      await inicializar();
    }
    _itens.remove(id);
    if (_itens.isEmpty) {
      _lojaId = null;
    }
    notifyListeners();
    await CarrinhoUtil.salvarCarrinho(_itens, _lojaId);
  }

  Future<void> decrementarItem(String id) async {
    if (!_inicializado) {
      await inicializar();
    }
    if (_itens.containsKey(id)) {
      final int qtd = ((_itens[id]!['quantidade'] ?? 1) as num).toInt();
      if (qtd > 1) {
        _itens[id]!['quantidade'] = qtd - 1;
      } else {
        _itens.remove(id);
        if (_itens.isEmpty) {
          _lojaId = null;
        }
      }
      notifyListeners();
      await CarrinhoUtil.salvarCarrinho(_itens, _lojaId);
    }
  }

  Future<void> limparCarrinho() async {
    _itens.clear();
    _lojaId = null;
    _inicializado = true;
    notifyListeners();
    await CarrinhoUtil.limparCarrinho();
  }
}

