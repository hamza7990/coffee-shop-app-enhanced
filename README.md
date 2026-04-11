# ☕ Brewhaus – Coffee Shop Management System

Brewhaus is a modern **Flutter-based Coffee Shop Management System** designed to streamline daily operations for cafés and small restaurants.
It provides a fast, intuitive interface for managing orders, menu items, tables, and real-time updates between cashier and kitchen.

---

## 🚀 Features

### 🧾 Order Management

* Create and manage **Dine-In** and **Takeaway** orders
* Update order status (Pending → Preparing → Completed)
* Track orders in real-time

### 📋 Menu Management

* View categories and menu items
* Filter by category
* Upload product images

### 🪑 Tables & Reservations

* Manage tables بسهولة
* Create and track reservations
* Organize customer flow داخل الكافيه

### 🔄 Real-Time Updates

* Live order status updates باستخدام **SignalR**
* Kitchen receives new orders instantly

### 🔐 Authentication

* Secure login باستخدام JWT
* Token storage باستخدام SharedPreferences

---

## 🛠️ Tech Stack

* **Flutter** – Cross-platform UI
* **Dio** – API integration
* **Riverpod** – State management
* **SignalR** – Real-time communication
* **SharedPreferences** – Local storage
* **Flutter Secure Storage** – Sensitive data protection

---

## 📁 Project Structure

```bash
lib/
│── core/           # API client & utilities
│── features/
│   ├── auth/       # Login & authentication
│   ├── menu/       # Menu & categories
│   ├── orders/     # Orders logic
│   ├── tables/     # Tables & reservations
│── services/       # API services (Dio)
│── main.dart
```

---

## ⚙️ Setup & Installation

### 1️⃣ Clone the repository

```bash
git clone https://github.com/your-username/brewhaus.git
cd brewhaus
```

### 2️⃣ Install dependencies

```bash
flutter pub get
```

### 3️⃣ Configure API URL

Edit `ApiClient`:

```dart
static const String baseUrl = 'http://YOUR_IP:5000/api';
```

📌 For Emulator:

* Android → `10.0.2.2`
* Real device → your local IP

---

### 4️⃣ Run the app

```bash
flutter run
```

---

## 🔌 Backend Integration

This app connects to a RESTful API that provides:

* Authentication (JWT)
* Menu & categories
* Orders management
* Tables & reservations
* Real-time updates via SignalR

---

## 📡 Real-Time (SignalR)

* Users receive live updates when:

  * Order status changes
  * New orders are created
* Kitchen screen updates instantly

---

## 📸 Screenshots (Coming Soon)

> Add screenshots here to showcase UI

---

## 🎯 Future Improvements

* 📊 Sales dashboard & analytics
* 🧑‍🍳 Kitchen display screen
* 💳 Online payments integration
* 🌐 Multi-language support
* 📱 Better UI/UX animations

---

## 🤝 Contributing

Contributions are welcome!
Feel free to fork the repo and submit a pull request.

---

## 📄 License

This project is licensed under the MIT License.

---

## 👨‍💻 Author

**Hamza Saied**
Computer Science Student | Flutter Developer | AI Enthusiast

---

## ⭐ Support

If you like this project, give it a ⭐ on GitHub!
