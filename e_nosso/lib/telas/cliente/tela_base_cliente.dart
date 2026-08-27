import 'package:flutter/material.dart';
import 'tela_inicial_comum.dart';
import 'tela_lojas_favoritas.dart';
import 'tela_pedidos_pendentes_cliente.dart';
import 'tela_carrinho.dart';

class TelaBaseCliente extends StatefulWidget {
  const TelaBaseCliente({super.key});

  @override
  State<TelaBaseCliente> createState() => _TelaBaseClienteState();
}

class _TelaBaseClienteState extends State<TelaBaseCliente> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      // Ao tocar na aba atual, volta até a tela inicial da aba
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Widget _buildTabNavigator(int index, Widget rootPage) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => rootPage,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final currentNavigatorState = _navigatorKeys[_currentIndex].currentState;
        if (currentNavigatorState != null && currentNavigatorState.canPop()) {
          currentNavigatorState.pop();
        } else if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildTabNavigator(0, const TelaInicialComum()),
            _buildTabNavigator(1, const TelaLojasFavoritas()),
            _buildTabNavigator(2, const TelaPedidosPendentesCliente()),
            _buildTabNavigator(3, const TelaRevisaoCarrinho(lojaName: "Sua Sacola")),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star_border),
              activeIcon: Icon(Icons.star),
              label: 'Favoritos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Pedidos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Carrinho',
            ),
          ],
        ),
      ),
    );
  }
}
