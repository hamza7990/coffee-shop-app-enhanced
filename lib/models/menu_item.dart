// lib/models/menu_item.dart
// ─────────────────────────────────────────────────────────────
// Pure data class for a menu item. No Flutter dependencies.
// Use copyWith() to produce modified copies (immutable style).
// ─────────────────────────────────────────────────────────────

enum MenuCategory { coffee, coldDrinks, desserts, snacks }

extension MenuCategoryExt on MenuCategory {
  String get label {
    switch (this) {
      case MenuCategory.coffee:     return 'Coffee';
      case MenuCategory.coldDrinks: return 'Cold Drinks';
      case MenuCategory.desserts:   return 'Desserts';
      case MenuCategory.snacks:     return 'Snacks';
    }
  }

  String get emoji {
    switch (this) {
      case MenuCategory.coffee:     return '☕';
      case MenuCategory.coldDrinks: return '🧊';
      case MenuCategory.desserts:   return '🍰';
      case MenuCategory.snacks:     return '🥐';
    }
  }
}

class MenuItem {
  final String id;
  final String name;
  final MenuCategory category;
  final double price;
  final String icon;
  final bool enabled;

  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.icon,
    this.enabled = true,
  });

  MenuItem copyWith({
    String? id,
    String? name,
    MenuCategory? category,
    double? price,
    String? icon,
    bool? enabled,
  }) =>
      MenuItem(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        price: price ?? this.price,
        icon: icon ?? this.icon,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'price': price,
        'icon': icon,
        'enabled': enabled,
      };

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: MenuCategory.values.firstWhere(
            (e) => e.name == json['category'],
            orElse: () => MenuCategory.coffee),
        price: (json['price'] as num).toDouble(),
        icon: json['icon'] as String? ?? '☕',
        enabled: json['enabled'] as bool? ?? true,
      );

  /// Convert from backend API format (MenuItemDto)
  /// Backend uses: Id, Name, Description, Price, ImageUrl, IsAvailable, CategoryId, CategoryName
  factory MenuItem.fromApiJson(Map<String, dynamic> json) => MenuItem(
        id: json['id']?.toString() ?? json['Id']?.toString() ?? '0',
        name: json['name'] as String? ?? json['Name'] as String? ?? 'Unknown',
        category: _parseCategory(json['categoryName'] as String? ?? json['CategoryName'] as String? ?? ''),
        price: (json['price'] as num? ?? json['Price'] as num? ?? 0).toDouble(),
        icon: _categoryToEmoji(_parseCategory(json['categoryName'] as String? ?? json['CategoryName'] as String? ?? '')),
        enabled: json['isAvailable'] as bool? ?? json['IsAvailable'] as bool? ?? true,
      );

  /// Convert to backend API format for CreateMenuItemRequest
  Map<String, dynamic> toApiJson() => {
        'name': name,
        'description': '',
        'price': price,
        'categoryId': _categoryToId(category),
      };

  static MenuCategory _parseCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'hot drinks':
      case 'coffee':
        return MenuCategory.coffee;
      case 'cold drinks':
        return MenuCategory.coldDrinks;
      case 'food & snacks':
      case 'snacks':
        return MenuCategory.snacks;
      case 'desserts':
        return MenuCategory.desserts;
      default:
        return MenuCategory.coffee;
    }
  }

  static String _categoryToEmoji(MenuCategory category) {
    switch (category) {
      case MenuCategory.coffee:     return '☕';
      case MenuCategory.coldDrinks: return '🧊';
      case MenuCategory.desserts:   return '🍰';
      case MenuCategory.snacks:     return '🥐';
    }
  }

  static int _categoryToId(MenuCategory category) {
    switch (category) {
      case MenuCategory.coffee:     return 1;
      case MenuCategory.coldDrinks: return 2;
      case MenuCategory.snacks:     return 3;
      case MenuCategory.desserts:   return 3;
    }
  }

  @override
  bool operator ==(Object other) => other is MenuItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
