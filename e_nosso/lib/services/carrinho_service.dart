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

  Map<String, Map<String, dynamic>> get itens => _itens;
  String? get lojaId => _lojaId;
  
  int get quantidadeTotal => _itens.values.fold(0, (sum, item) => sum + ((item['quantidade'] ?? 0) as num).toInt());
  
  bool get isEmpty => _itens.isEmpty;
  bool get isNotEmpty => _itens.isNotEmpty;

  Future<void> inicializar() async {
    final dados = await CarrinhoUtil.carregarCarrinho();
    _itens.clear();
    if (dados['carrinho'] != null) {
      _itens.addAll(dados['carrinho'] as Map<String, Map<String, dynamic>>);
    }
    _lojaId = dados['lojaId'] as String?;
    notifyListeners();
  }

  Future<void> adicionarItem(String id, Map<String, dynamic> item, String lojaId) async {
    if (_lojaId != null && _lojaId != lojaId && _itens.isNotEmpty) {
      _itens.clear();
    }
    _lojaId = lojaId;

    if (_itens.containsKey(id)) {
      _itens[id]!['quantidade'] = (_itens[id]!['quantidade'] as int) + (item['quantidade'] as int);
    } else {
      _itens[id] = Map<String, dynamic>.from(item);
    }
    
    notifyListeners();
    await CarrinhoUtil.salvarCarrinho(_itens, _lojaId);
  }

  Future<void> removerItem(String id) async {
    _itens.remove(id);
    if (_itens.isEmpty) {
      _lojaId = null;
    }
    notifyListeners();
    await CarrinhoUtil.salvarCarrinho(_itens, _lojaId);
  }

  Future<void> decrementarItem(String id) async {
    if (_itens.containsKey(id)) {
      int qtd = _itens[id]!['quantidade'] as int;
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
    notifyListeners();
    await CarrinhoUtil.limparCarrinho();
  }
}
