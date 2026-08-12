import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Ícono + color de acento para representar un producto visualmente
/// (reemplaza las cards de solo texto por algo con más carácter).
class ProductVisual {
  const ProductVisual({
    required this.icon,
    required this.accent,
    required this.container,
  });

  final IconData icon;
  final Color accent;
  final Color container;
}

/// Deriva un [ProductVisual] a partir del nombre del producto: primero
/// intenta matchear palabras clave de comida/bebida bolivianas comunes: si
/// no reconoce el nombre, cae a un ícono + color determinístico (mismo
/// nombre → siempre el mismo resultado) tomado de una paleta variada, así
/// ningún producto queda con la tile vacía o repetida sin sentido.
class ProductVisuals {
  ProductVisuals._();

  static final Map<RegExp, IconData> _keywordIcons = {
    RegExp(r'caf[eé]|espresso|capuchino|latte'): LucideIcons.coffee,
    RegExp(r't[eé]\b|mate'): LucideIcons.leaf,
    RegExp(r'jugo|refresco|gaseosa|soda|naranja'): LucideIcons.citrus,
    RegExp(r'agua'): LucideIcons.droplet,
    RegExp(r'cerveza|birra'): LucideIcons.beer,
    RegExp(r'vino'): LucideIcons.wine,
    RegExp(r'coctel|trago'): LucideIcons.martini,
    RegExp(r'empanada|salte[nñ]a|pan\b|sandwich|sandu[ií]che'):
        LucideIcons.croissant,
    RegExp(r'hamburguesa|burger'): LucideIcons.hamburger,
    RegExp(r'pizza'): LucideIcons.pizza,
    RegExp(r'pollo|carne|milanesa|churrasco|parrilla'): LucideIcons.forkKnife,
    RegExp(r'ensalada|palta|aguacate'): LucideIcons.salad,
    RegExp(r'zanahoria|verdura'): LucideIcons.carrot,
    RegExp(r'pescado|sushi'): LucideIcons.fish,
    RegExp(r'torta|pastel|cake|queque'): LucideIcons.cake,
    RegExp(r'galleta|cookie'): LucideIcons.cookie,
    RegExp(r'helado|ice ?cream'): LucideIcons.iceCream,
    RegExp(r'palomita|pop ?corn|canchita'): LucideIcons.popcorn,
    RegExp(r'sopa|caldo|guiso'): LucideIcons.soup,
  };

  /// Paleta de acentos (cada uno con su tono contenedor claro para el fondo
  /// de la tile). No son tokens semánticos — solo variedad visual.
  static const List<(Color accent, Color container)> _palette = [
    (Color(0xFF4F46E5), Color(0xFFE0E7FF)), // indigo
    (Color(0xFF7C3AED), Color(0xFFEDE9FE)), // violeta
    (Color(0xFFEA580C), Color(0xFFFFEDD5)), // naranja
    (Color(0xFF0891B2), Color(0xFFCFFAFE)), // cyan
    (Color(0xFFDB2777), Color(0xFFFCE7F3)), // rosa
    (Color(0xFF16A34A), Color(0xFFDCFCE7)), // verde
    (Color(0xFFCA8A04), Color(0xFFFEF9C3)), // amarillo
  ];

  static ProductVisual of(String productName) {
    final name = productName.toLowerCase();

    for (final entry in _keywordIcons.entries) {
      if (entry.key.hasMatch(name)) {
        final (accent, container) = _colorFor(name);
        return ProductVisual(icon: entry.value, accent: accent, container: container);
      }
    }

    final (accent, container) = _colorFor(name);
    return ProductVisual(
      icon: LucideIcons.utensils,
      accent: accent,
      container: container,
    );
  }

  static (Color, Color) _colorFor(String name) {
    final index = name.codeUnits.fold<int>(0, (sum, c) => sum + c) % _palette.length;
    return _palette[index];
  }
}
