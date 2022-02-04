import 'package:flutter/material.dart';

/// Maneja el estado de la navegación principal.
/// 
/// Es utilizado principalmente para coordinar la navegación propagando los 
/// cambios entre un [PageView] y una [BottomNavigationBar].
class NavigationProvider with ChangeNotifier {

  /// El índice de la página activa en la navegación.
  int _activePage = 0;

  /// Controlador para el [PageView] principal.
  final PageController _pageController = PageController();

  /// Obtiene el índice de la página activa.
  int get activePage => _activePage;

  /// Realiza una transición de la página actual a [newPage].
  /// 
  /// Primero cambia el valor interno del índice de la página activa. Luego 
  /// realiza una transición entre la página anterior y la nueva usando el 
  /// [_pageController]. Finalmente, notifica a todos los listeners del estado.
  set activePage (int newPage) {
    _activePage = newPage;

    _pageController.animateToPage(
      _activePage, 
      duration: const Duration(milliseconds: 300), 
      curve: Curves.ease
    );

    notifyListeners();
  } 

  /// Obtiene el controlador del [PageView] principal.
  PageController get pageController => _pageController;
}