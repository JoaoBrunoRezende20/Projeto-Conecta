import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CarrinhoUtil {
  static const String _carrinhoKey = 'carrinho_global';
  static const String _lojaIdKey = 'loja_id_carrinho';

  // Salva o carrinho inteiro (mapa e loja ID)
  static Future<void> salvarCarrinho(
      Map<String, Map<String, dynamic>> carrinho, String? lojaId) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (carrinho.isEmpty) {
      await prefs.remove(_carrinhoKey);
      await prefs.remove(_lojaIdKey);
      return;
    }

    final jsonString = jsonEncode(carrinho);
    await prefs.setString(_carrinhoKey, jsonString);
    
    if (lojaId != null) {
      await prefs.setString(_lojaIdKey, lojaId);
    } else {
      await prefs.remove(_lojaIdKey);
    }
  }

  // Carrega o carrinho salvo da memória local
  static Future<Map<String, dynamic>> carregarCarrinho() async {
    final prefs = await SharedPreferences.getInstance();
    
    final jsonString = prefs.getString(_carrinhoKey);
    final lojaId = prefs.getString(_lojaIdKey);

    Map<String, Map<String, dynamic>> carrinhoCarregado = {};
    
    if (jsonString != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        decoded.forEach((key, value) {
          carrinhoCarregado[key] = Map<String, dynamic>.from(value);
        });
      } catch (e) {
        // Ignora erros de parsing e retorna vazio
      }
    }

    return {
      'carrinho': carrinhoCarregado,
      'lojaId': lojaId,
    };
  }

  // Limpa o carrinho salvo
  static Future<void> limparCarrinho() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_carrinhoKey);
    await prefs.remove(_lojaIdKey);
  }
}
