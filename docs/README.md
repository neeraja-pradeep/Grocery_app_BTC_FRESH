# 📚 BTC Grocery App - Documentation Index

Welcome to the comprehensive documentation for the BTC Grocery App. All documentation has been organized into logical categories for easy navigation.

## 📖 Quick Navigation

- [🚀 Getting Started](#-getting-started)
- [🏗️ Architecture](#️-architecture)
- [✨ Features](#-features)
- [👨‍💻 Development Guidelines](#-development-guidelines)
- [🔌 API Documentation](#-api-documentation)
- [🎨 Design](#-design)
- [✅ QA & Testing](#-qa--testing)

---

## 🚀 Getting Started

Essential documentation to get started with the project.

| Document | Description |
|----------|-------------|
| [README](01-Getting-Started/README.md) | Project overview and introduction |
| [Quick Start](01-Getting-Started/QUICK_START.md) | Quick setup guide for developers |
| [Setup Guide](01-Getting-Started/SETUP.md) | Detailed setup instructions |
| [Setup Summary](01-Getting-Started/SETUP_SUMMARY.md) | Setup checklist and summary |

---

## 🏗️ Architecture

Deep dive into the app's architecture and technical implementation.

### 🌐 Network Layer
| Document | Description |
|----------|-------------|
| [HTTP Caching Overview](02-Architecture/Network/IF_MODIFIED_SINCE_README.md) | Introduction to If-Modified-Since caching |
| [Caching Architecture](02-Architecture/Network/IF_MODIFIED_SINCE_ARCHITECTURE.md) | Detailed caching architecture |
| [Caching Quick Reference](02-Architecture/Network/IF_MODIFIED_SINCE_QUICK_REFERENCE.md) | Quick reference for HTTP caching |
| [Caching Code Examples](02-Architecture/Network/IF_MODIFIED_SINCE_CODE_EXAMPLES.md) | Implementation examples |
| [Caching Flow Diagrams](02-Architecture/Network/IF_MODIFIED_SINCE_FLOW_DIAGRAMS.md) | Visual flow diagrams |
| [Socket.IO Integration](02-Architecture/Network/SOCKET_IO_INTEGRATION.md) | Real-time communication setup |
| [Socket.IO Debug Guide](02-Architecture/Network/SOCKET_IO_DEBUG_GUIDE.md) | Debugging Socket.IO connections |

### 🔄 State Management
| Document | Description |
|----------|-------------|
| [Delivery & Rating Flow](02-Architecture/State-Management/DELIVERY_AND_RATING_FLOW.md) | State management for delivery and ratings |

### 💾 Storage
| Document | Description |
|----------|-------------|
| [Hive Implementation](02-Architecture/Storage/HIVE%20implementation.md) | Local caching with Hive database |

### ⚡ Performance
| Document | Description |
|----------|-------------|
| [Screen-Aware Polling Guide](02-Architecture/Performance/SCREEN_AWARE_POLLING_GUIDE.md) | Guide to screen-aware polling |
| [Polling Optimization Setup](02-Architecture/Performance/POLLING_OPTIMIZATION_QUICK_SETUP.md) | Quick setup for polling optimization |
| [Polling Implementation](02-Architecture/Performance/POLLING_IMPLEMENTATION_SUMMARY.md) | Implementation summary |
| [Complete Polling Docs](02-Architecture/Performance/SCREEN_AWARE_POLLING_COMPLETE.md) | Comprehensive polling documentation |

### 📱 UI & Responsiveness
| Document | Description |
|----------|-------------|
| [ScreenUtil Implementation](02-Architecture/UI-Responsiveness/FLUTTER_SCREENUTIL_IMPLEMENTATION_COMPLETE.md) | Responsive design with flutter_screenutil |

### 📋 Overview
| Document | Description |
|----------|-------------|
| [Cleanup Summary](02-Architecture/Overview/CLEANUP_SUMMARY.md) | Architecture cleanup and maintenance |

---

## ✨ Features

Implementation details for specific features.

### 🏠 Home & Categories
| Document | Description |
|----------|-------------|
| [**Home & Category Flow**](03-Features/Home/HOME_CATEGORY_FLOW.md) | Browse categories, product listing, address bar |

### 📍 Address
| Document | Description |
|----------|-------------|
| [**Address Flow**](03-Features/Address/ADDRESS_FLOW.md) | Add/Edit/Delete/Select address, sync across providers |

### 🛒 Cart
| Document | Description |
|----------|-------------|
| [**Cart Flow**](03-Features/Cart/CART_FLOW.md) | Add to cart, quantity updates, cart summary |
| [Payment Flow](payment_flow.md) | Complete checkout and payment process |

### ❤️ Wishlist
| Document | Description |
|----------|-------------|
| [**Wishlist Flow**](03-Features/Wishlist/WISHLIST_FLOW.md) | Add/remove wishlist items, move to cart |

### 📦 Orders
| Document | Description |
|----------|-------------|
| [**Orders Flow**](03-Features/Orders/ORDERS_FLOW.md) | Order history, details, reorder, rating |
| [Reorder Flow](reorder_flow.md) | Reorder previous orders |
| [**Order Rating Complete Summary**](ORDER_RATING_COMPLETE_SUMMARY.md) | High-level overview of all rating implementations |
| [Order Rating Update Implementation](ORDER_RATING_UPDATE_IMPLEMENTATION.md) | Complete order rating feature implementation |
| [Rating Display Fix](RATING_DISPLAY_FIX.md) | Fix for displaying existing ratings in order history |
| [Critical PATCH Endpoint Fix](CRITICAL_PATCH_ENDPOINT_FIX.md) | Fix for rating update endpoint with rating_id in URL |

### 🧭 Navigation
| Document | Description |
|----------|-------------|
| [**Navigation Flow**](03-Features/Navigation/NAVIGATION_FLOW.md) | Bottom nav, back button, deep linking, routing |

### 🔍 Search
| Document | Description |
|----------|-------------|
| [Search Improvements](03-Features/Search/SEARCH_IMPROVEMENTS.md) | Search feature enhancements |
| [Search Implementation](03-Features/Search/SEARCH_IMPLEMENTATION.md) | Core search implementation |
| [Unified Search](03-Features/Search/UNIFIED_SEARCH_IMPLEMENTATION.md) | Unified search system |

### 💳 Payment
| Document | Description |
|----------|-------------|
| [Razorpay Fix](03-Features/Payment/RAZORPAY_FIX_README.md) | Razorpay integration fixes |
| [Razorpay Debug Guide](03-Features/Payment/RAZORPAY_DEBUG_VS_RELEASE.md) | Debug vs Release configuration |
| [Currency Conversion](03-Features/Payment/CURRENCY_CONVERSION_SUMMARY.md) | Currency conversion feature |

### 🚚 Delivery
| Document | Description |
|----------|-------------|
| [**Delivery Tracking Persistence**](DELIVERY_TRACKING_PERSISTENCE.md) | Persist DeliveryStatusBar across app restarts using Hive |
| [Delivery Status Flow](03-Features/Delivery/delivery_status_flow.md) | Delivery status tracking |

### 🎨 UI Components
| Document | Description |
|----------|-------------|
| [Pull-to-Refresh Fix](03-Features/UI/PULL_TO_REFRESH_FIX.md) | Bug fix for pull-to-refresh |
| [Pull-to-Refresh Implementation](03-Features/UI/PULL_TO_REFRESH_IMPLEMENTATION.md) | Implementation guide |

### 🔐 Authentication
| Document | Description |
|----------|-------------|
| [Auth & Guest Mode](03-Features/Authentication/AUTH_GUEST_MODE.md) | Authentication and guest mode |

### ⚡ Real-time Features
| Document | Description |
|----------|-------------|
| [Category Socket.IO](03-Features/RealTime/SOCKET_IO_CATEGORY_INTEGRATION.md) | Real-time category updates |

### 🛍️ Product Details
| Document | Description |
|----------|-------------|
| [Product Details Architecture](03-Features/ProductDetails/ARCHITECTURE.md) | Feature architecture |

---

## 👨‍💻 Development Guidelines

Standards and best practices for development.

| Document | Description |
|----------|-------------|
| [Flutter Coding Standards](04-Development-Guidelines/Flutter%20Coding%20Standards.md) | Project coding standards |
| [Mobile Responsiveness](04-Development-Guidelines/Flutter%20Mobile%20Responsiveness%20using%20flutter_screenutil.md) | Responsive design guidelines |
| [Linting & Analysis](04-Development-Guidelines/Linting%20&%20Analysis(implementation%20guide)-Flutter.md) | Code quality tools setup |
| [Pre-Commit Hooks](04-Development-Guidelines/Pre-Commit%20Hook%20Setup%20Guide.md) | Git hooks configuration |

---

## 🔌 API Documentation

Backend API integration details.

| Document | Description |
|----------|-------------|
| [API Integration](05-API-Documentation/API%20Integration%20Document%20-%20BTC%20Grocery.md) | Complete API reference |

---

## 🎨 Design

Design resources and references.

| Document | Description |
|----------|-------------|
| [Figma UI/UX](06-Design/figma%20for%20uiux.md) | Figma design specifications |

---

## ✅ QA & Testing

Quality assurance and testing documentation.

| Document | Description |
|----------|-------------|
| [QA Guide](07-QA-Testing/QA.md) | Quality assurance prompts and audits |

---

## 📂 Folder Structure

```
docs/
├── 01-Getting-Started/          # Setup and onboarding
├── 02-Architecture/              # Technical architecture
│   ├── Network/                  # HTTP caching, Socket.IO
│   ├── State-Management/         # State management patterns
│   ├── Storage/                  # Local storage (Hive)
│   ├── Performance/              # Polling, optimization
│   ├── UI-Responsiveness/        # Responsive design
│   └── Overview/                 # General architecture
├── 03-Features/                  # Feature-specific docs
│   ├── Address/                  # Address management
│   ├── Authentication/           # Auth & guest mode
│   ├── Cart/                     # Cart & checkout
│   ├── Delivery/                 # Delivery tracking
│   ├── Home/                     # Home & categories
│   ├── Navigation/               # App navigation & routing
│   ├── Orders/                   # Order history & rating
│   ├── Payment/                  # Payment integration
│   ├── ProductDetails/           # Product details
│   ├── RealTime/                 # Real-time features
│   ├── Search/                   # Search functionality
│   ├── UI/                       # UI components
│   └── Wishlist/                 # Wishlist feature
├── 04-Development-Guidelines/    # Coding standards
├── 05-API-Documentation/         # Backend API docs
├── 06-Design/                    # Design resources
└── 07-QA-Testing/               # QA and testing
```

---

## 🔍 Most Important Documents

### For New Developers
1. [README](01-Getting-Started/README.md) - Start here
2. [Quick Start](01-Getting-Started/QUICK_START.md) - Get up and running
3. [Flutter Coding Standards](04-Development-Guidelines/Flutter%20Coding%20Standards.md) - Follow our conventions

### For Architecture Understanding
1. [HTTP Caching Overview](02-Architecture/Network/IF_MODIFIED_SINCE_README.md) - Core optimization (90% bandwidth reduction)
2. [Product Details Architecture](03-Features/ProductDetails/ARCHITECTURE.md) - Example feature architecture
3. [Delivery & Rating Flow](02-Architecture/State-Management/DELIVERY_AND_RATING_FLOW.md) - State management example

### For Backend Integration
1. [API Integration](05-API-Documentation/API%20Integration%20Document%20-%20BTC%20Grocery.md) - Complete API reference
2. [Socket.IO Integration](02-Architecture/Network/SOCKET_IO_INTEGRATION.md) - Real-time communication

---

## 📝 Documentation Statistics

- **Total Documents**: 44 markdown files
- **Categories**: 7 main categories
- **Subcategories**: 19 specialized sections
- **Coverage**: Setup, Architecture, Features, Guidelines, API, Design, QA

### New Flow Documentation (Dec 2025)
- Address Flow - Add/Edit/Delete/Select addresses
- Cart Flow - Shopping cart management
- Wishlist Flow - Save products for later
- Home & Category Flow - Product browsing
- Orders Flow - Order history and rating
- Navigation Flow - App navigation and routing

---

## 🤝 Contributing

When adding new documentation:
1. Place it in the appropriate category folder
2. Update this README index
3. Follow the existing naming conventions
4. Include clear descriptions and examples

---

## ⚠️ Important Notes

### Files with Merge Conflicts
Some files may contain unresolved Git merge markers. Please resolve these before using:
- API Integration Document
- Flutter Coding Standards
- Mobile Responsiveness Guide
- Linting & Analysis Guide
- Pre-Commit Hook Setup Guide
- QA Guide

---

**Last Updated**: 2025-12-25
**Maintained By**: BTC Grocery Development Team
