# 🛒 BTC Grocery App

A modern Flutter-based grocery delivery application with real-time updates, intelligent caching, and seamless payment integration.

## 🚀 Quick Start

New to the project? Check out our comprehensive documentation:

📚 **[View Complete Documentation](docs/README.md)**

### Essential Links
- [Quick Start Guide](docs/01-Getting-Started/QUICK_START.md) - Get up and running in minutes
- [Setup Instructions](docs/01-Getting-Started/SETUP.md) - Detailed setup guide
- [Coding Standards](docs/04-Development-Guidelines/Flutter%20Coding%20Standards.md) - Development guidelines

## ✨ Key Features

- 🛍️ **Product Browsing** - Browse categories and products with real-time updates
- 🔍 **Smart Search** - Unified search across products and categories
- 🛒 **Shopping Cart** - Add, update, and manage cart items
- 💳 **Payment Integration** - Razorpay payment gateway integration
- 🚚 **Delivery Tracking** - Real-time delivery status updates
- ⭐ **Order Rating** - Rate your orders and provide feedback
- 👤 **Guest Mode** - Browse and shop without registration
- ⚡ **Offline Support** - Intelligent caching with Hive database
- 🌐 **HTTP Caching** - If-Modified-Since caching (90% bandwidth reduction)
- 🔄 **Real-time Updates** - Socket.IO integration for live data

## 🏗️ Architecture Highlights

- **Clean Architecture** - Separation of concerns with domain, data, and presentation layers
- **Riverpod State Management** - Reactive state management
- **HTTP Caching** - Smart caching to reduce bandwidth and improve performance
- **Screen-Aware Polling** - Optimized polling based on screen visibility
- **Responsive Design** - flutter_screenutil for cross-device compatibility

## 📱 Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Riverpod
- **Local Storage**: Hive
- **Network**: Dio with HTTP caching
- **Real-time**: Socket.IO
- **Payment**: Razorpay
- **UI**: flutter_screenutil for responsiveness

## 📖 Documentation Structure

Our documentation is organized into 7 main categories:

1. **[Getting Started](docs/01-Getting-Started/)** - Setup and onboarding
2. **[Architecture](docs/02-Architecture/)** - Technical architecture and patterns
3. **[Features](docs/03-Features/)** - Feature-specific implementation guides
4. **[Development Guidelines](docs/04-Development-Guidelines/)** - Coding standards and best practices
5. **[API Documentation](docs/05-API-Documentation/)** - Backend API reference
6. **[Design](docs/06-Design/)** - Design resources and Figma references
7. **[QA & Testing](docs/07-QA-Testing/)** - Quality assurance guides

## 🛠️ Development Setup

### Prerequisites
- Flutter SDK (3.x or higher)
- Android Studio / Xcode
- Git

### Quick Setup

```bash
# Clone the repository
git clone <repository-url>
cd grocery_app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

For detailed setup instructions, see [Setup Guide](docs/01-Getting-Started/SETUP.md).

## 🔧 Configuration

### Environment Setup
- Configure API endpoints in `lib/core/config/app_config.dart`
- Set up Razorpay keys for payment integration
- Configure Socket.IO connection settings

See [API Integration Document](docs/05-API-Documentation/API%20Integration%20Document%20-%20BTC%20Grocery.md) for details.

## 📚 Learning Resources

### For New Developers
1. Start with [Quick Start Guide](docs/01-Getting-Started/QUICK_START.md)
2. Review [Flutter Coding Standards](docs/04-Development-Guidelines/Flutter%20Coding%20Standards.md)
3. Understand [HTTP Caching](docs/02-Architecture/Network/IF_MODIFIED_SINCE_README.md)

### For Architecture Deep Dive
1. [Product Details Architecture](docs/03-Features/ProductDetails/ARCHITECTURE.md) - Example feature architecture
2. [Delivery & Rating Flow](docs/02-Architecture/State-Management/DELIVERY_AND_RATING_FLOW.md) - State management patterns
3. [Socket.IO Integration](docs/02-Architecture/Network/SOCKET_IO_INTEGRATION.md) - Real-time features

## 🤝 Contributing

1. Follow our [Coding Standards](docs/04-Development-Guidelines/Flutter%20Coding%20Standards.md)
2. Set up [Pre-Commit Hooks](docs/04-Development-Guidelines/Pre-Commit%20Hook%20Setup%20Guide.md)
3. Follow [Linting Guidelines](docs/04-Development-Guidelines/Linting%20&%20Analysis(implementation%20guide)-Flutter.md)

## 📄 License

[Add your license information here]

## 👥 Team

BTC Grocery Development Team

---

**For complete documentation, visit [docs/README.md](docs/README.md)**
