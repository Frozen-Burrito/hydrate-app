import 'package:flutter/material.dart';

/// Maneja el estado de la navegación principal.
/// 
/// Es utilizado principalmente para propagar los cambios de navegación en 
/// un [PageView] y una [BottomNavigationBar].
class NavigationProvider with ChangeNotifier {

  /// El índice de la página activa en la navegación.
  int _activePage = 0;

  /// Controlador para el [PageView] principal.
  final PageController _pageController = PageController();

  /// Es `true` si el controlador está animando una transición.
  bool isAnimatingPageChange = false;

  /// Obtiene el índice de la página activa.
  int get activePage => _activePage;

  /// Realiza una transición desde la página actual a [newPage].
  /// 
  /// Primero cambia el valor interno del índice de la página activa. Luego 
  /// realiza una transición entre la página anterior y la nueva usando el 
  /// [_pageController]. Finalmente, notifica a todos los listeners del estado.
  set activePage (int newPage) {

    if (isAnimatingPageChange) return;

    assert(newPage >= 0 && newPage < 3);

    _activePage = newPage;

    isAnimatingPageChange = true;
  
    // Animar la transición a la nueva página, evitando temporalmente que el 
    // índice de la página sea modificado durante la transición.
    _pageController.animateToPage(
      _activePage, 
      duration: const Duration(milliseconds: 200), 
      curve: Curves.ease
    ).whenComplete(() => isAnimatingPageChange = false);

    notifyListeners();
  } 

  /// Obtiene el controlador del [PageView] principal.
  PageController get pageController => _pageController;
}