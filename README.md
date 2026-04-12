# ☕ Brewhaus — Flutter Coffee Shop Management System

A complete, production-ready Flutter application for managing a coffee shop.
Covers Tables, Orders, Menu, Payments, and Sales Analytics.

---

## 📁 Project Structure

```
brewhaus/
├── pubspec.yaml                  ← dependencies & assets
└── lib/
    ├── main.dart                 ← entry point + MultiProvider + auth gate
    │
    ├── theme/
    │   └── app_theme.dart        ← ALL colors, text styles, ThemeData (light+dark)
    │
    ├── models/                   ← Pure Dart data classes (no Flutter imports)
    │   ├── menu_item.dart        ← MenuItem + MenuCategory enum
    │   ├── coffee_table.dart     ← CoffeeTable + TableStatus enum
    │   └── order.dart            ← Order + OrderItem + enums
    │
    ├── data/
    │   └── sample_data.dart      ← Seed lists (menu, tables, orders, chart data)
    │
    ├── providers/                ← State management (ChangeNotifier + Provider)
    │   ├── theme_provider.dart   ← isDark bool + toggleTheme()
    │   ├── auth_provider.dart    ← isLoggedIn, login(), logout()
    │   ├── menu_provider.dart    ← CRUD for menu items
    │   ├── table_provider.dart   ← table status, assign/free
    │   └── order_provider.dart   ← create/update/complete orders
    │
    ├── widgets/
    │   └── common_widgets.dart   ← AppCard, StatCard, AppButton, StatusBadge, etc.
    │
    └── screens/
        ├── login_screen.dart     ← Login page
        ├── home_screen.dart      ← Nav shell (Sidebar on wide / BottomBar on narrow)
        ├── dashboard_screen.dart ← KPI cards + charts + active orders
        ├── tables_screen.dart    ← Table grid + status management
        ├── new_order_sheet.dart  ← Bottom sheet: create new order
        ├── orders_screen.dart    ← Active orders (cards) + Completed (table)
        ├── payment_sheet.dart    ← Cash/Card payment + Receipt dialog
        ├── menu_screen.dart      ← Menu items grid + add/edit sheet
        └── analytics_screen.dart ← Revenue charts + category + payment pie
```

---

## 🏗️ State Management Architecture

This project uses the **Provider** package with `ChangeNotifier`.

### How it works

```
MultiProvider (main.dart)
├── ThemeProvider   → read anywhere to toggle dark mode
├── AuthProvider    → login/logout; root widget auto-swaps screens
├── MenuProvider    → list of MenuItem; CRUD methods
├── TableProvider   → list of CoffeeTable; assign/free tables
└── OrderProvider   → active + completed orders; create/complete
```

### Reading state in widgets

```dart
// Rebuild when data changes (in build())
final menu = context.watch<MenuProvider>();

// Fire a mutation without subscribing to rebuilds (in callbacks)
context.read<OrderProvider>().completeOrder(...);
```

### Data flow example (Place Order)

```
User taps "Place Order" in NewOrderSheet
  → context.read<OrderProvider>().createOrder(tableId, items)  // adds to _active list
  → context.read<TableProvider>().assignOrder(tableId, orderId) // sets status=occupied
  → Both providers call notifyListeners()
  → All watching widgets (Dashboard, Tables, Orders) rebuild automatically
```

---

## 🚀 How to Run

### Prerequisites

| Tool       | Version  | Install link |
|------------|----------|--------------|
| Flutter SDK | ≥ 3.0.0 | https://docs.flutter.dev/get-started/install |
| Dart SDK   | ≥ 3.0.0  | Included with Flutter |
| Android Studio **or** VS Code | latest | https://code.visualstudio.com |
| Android emulator **or** iOS Simulator (macOS only) | — | Via Android Studio AVD Manager |

> **Check your install:**
> ```bash
> flutter doctor
> ```
> All items should show ✓ (or at minimum the platform you want to run on).

---

### Step 1 — Get the project

```bash
# Option A: if you have the zip
unzip brewhaus.zip && cd brewhaus

# Option B: copy all the files from this project into a new folder called brewhaus
```

### Step 2 — Install dependencies

```bash
cd brewhaus
flutter pub get
```

This downloads:
- `provider` ^6.1.1 — state management
- `fl_chart` ^0.68.0 — charts
- `intl` ^0.19.0 — date formatting
- `uuid` ^4.3.3 — unique IDs for new menu items

The app uses **Playfair Display** (headings) and **DM Sans** (body) loaded automatically
via the `google_fonts` package — **no font files needed**, no `assets/fonts/` folder required.
Fonts are fetched from Google's CDN on first run and cached locally.

### Step 4 — Run on a device / emulator

```bash
# List available devices
flutter devices

# Run on a specific device
flutter run -d <device_id>

# Common examples:
flutter run -d chrome           # Web browser
flutter run -d windows          # Windows desktop
flutter run -d macos            # macOS desktop
flutter run -d emulator-5554    # Android emulator
flutter run -d iPhone-15        # iOS simulator (macOS only)
```

### Step 5 — Login

- **Email:** admin@brewhaus.com (or any non-empty email)  
- **Password:** `password`

---

## 🖥️ Running on Web (Recommended for quick demo)

```bash
flutter run -d chrome
```

The app uses a responsive layout:
- **Wide screen (≥ 800px)** → sidebar navigation
- **Narrow screen (< 800px)** → bottom navigation bar

---

## 📱 Running on Android

1. Open Android Studio → **Device Manager** → Create a Pixel 6 emulator
2. Start the emulator
3. Run:
   ```bash
   flutter run
   ```

---

## 🍎 Running on iOS (macOS only)

```bash
open -a Simulator   # start iOS Simulator
flutter run
```

---

## 🏗️ Building a Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle

# iOS (macOS only, requires Apple Developer account)
flutter build ios

# Web
flutter build web
```

---

## 🔧 Extending the App

### Connect to a real backend

Replace the seed data in `lib/data/sample_data.dart` with API calls.
Each provider's `_list` becomes fetched from your REST API:

```dart
// In MenuProvider
Future<void> fetchItems() async {
  final resp = await http.get(Uri.parse('https://yourapi.com/menu'));
  final data = jsonDecode(resp.body) as List;
  _items
    ..clear()
    ..addAll(data.map(MenuItem.fromJson));
  notifyListeners();
}
```

### Add persistent storage (local)

Use `shared_preferences` or `hive` to persist state between app launches:

```bash
flutter pub add hive hive_flutter
```

### Database schema (if building a backend)

```sql
CREATE TABLE menu_items (
  id        VARCHAR(36) PRIMARY KEY,
  name      VARCHAR(100) NOT NULL,
  category  VARCHAR(20)  NOT NULL,
  price     DECIMAL(6,2) NOT NULL,
  icon      VARCHAR(10),
  enabled   BOOLEAN DEFAULT TRUE
);

CREATE TABLE coffee_tables (
  id     INT PRIMARY KEY,
  name   VARCHAR(50),
  seats  INT NOT NULL,
  status VARCHAR(20) DEFAULT 'available'
);

CREATE TABLE orders (
  id             VARCHAR(36) PRIMARY KEY,
  table_id       INT REFERENCES coffee_tables(id),
  status         VARCHAR(20) DEFAULT 'active',
  payment_method VARCHAR(10),
  total          DECIMAL(8,2),
  created_at     TIMESTAMP DEFAULT NOW(),
  completed_at   TIMESTAMP
);

CREATE TABLE order_items (
  id           SERIAL PRIMARY KEY,
  order_id     VARCHAR(36) REFERENCES orders(id),
  menu_item_id VARCHAR(36) REFERENCES menu_items(id),
  quantity     INT  NOT NULL,
  note         TEXT
);
```

---

## 📦 Key Dependencies Explained

| Package | Why |
|---------|-----|
| `provider` | Recommended Flutter state management. Lightweight, no codegen. |
| `fl_chart` | Beautiful, customizable charts (Bar, Line, Pie). |
| `google_fonts` | Loads Playfair Display + DM Sans from CDN — zero font files needed. |
| `intl` | `DateFormat('HH:mm').format(DateTime.now())` for timestamps. |
| `uuid` | Generates unique IDs like `"3f2a1b..."` for new menu items. |

---

## ✅ Features Checklist

- [x] Login screen with dark/light toggle
- [x] Responsive sidebar + bottom nav
- [x] Dashboard: KPI cards, weekly bar chart, popular items, active orders
- [x] Table management: 12 tables, status badges, reserve/free/assign
- [x] Orders: active cards with qty controls, completed data table
- [x] New order: table selector, category filter, menu picker, live total
- [x] Payment: Cash (with change calc) + Card, receipt dialog
- [x] Menu CRUD: add, edit, delete, toggle active/inactive
- [x] Analytics: hourly line, weekly bar, category bars, payment pie
- [x] Full dark mode
- [x] Provider state management with no prop-drilling
