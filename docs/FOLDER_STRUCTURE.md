# 📁 Documentation Folder Structure

Complete visual guide to the documentation organization.

## 📂 Complete Structure

```
docs/
│
├── README.md                           # Master documentation index
├── FOLDER_STRUCTURE.md                 # This file
│
├── 01-Getting-Started/                 # 🚀 Setup & Onboarding (4 files)
│   ├── README.md                       # Project overview and introduction
│   ├── QUICK_START.md                  # Quick setup guide for developers
│   ├── SETUP.md                        # Detailed setup instructions
│   └── SETUP_SUMMARY.md                # Setup checklist and summary
│
├── 02-Architecture/                    # 🏗️ Technical Architecture (18 files)
│   │
│   ├── Network/                        # 🌐 Network Layer (7 files)
│   │   ├── IF_MODIFIED_SINCE_README.md             # HTTP caching overview
│   │   ├── IF_MODIFIED_SINCE_ARCHITECTURE.md       # Caching architecture details
│   │   ├── IF_MODIFIED_SINCE_QUICK_REFERENCE.md    # Caching quick reference
│   │   ├── IF_MODIFIED_SINCE_CODE_EXAMPLES.md      # Caching code examples
│   │   ├── IF_MODIFIED_SINCE_FLOW_DIAGRAMS.md      # Caching flow diagrams
│   │   ├── SOCKET_IO_INTEGRATION.md                # Real-time Socket.IO setup
│   │   └── SOCKET_IO_DEBUG_GUIDE.md                # Socket.IO debugging guide
│   │
│   ├── State-Management/               # 🔄 State Management (1 file)
│   │   └── DELIVERY_AND_RATING_FLOW.md             # Delivery & rating state flow
│   │
│   ├── Storage/                        # 💾 Local Storage (1 file)
│   │   └── HIVE implementation.md                  # Hive database caching
│   │
│   ├── Performance/                    # ⚡ Performance Optimization (4 files)
│   │   ├── SCREEN_AWARE_POLLING_GUIDE.md           # Screen-aware polling guide
│   │   ├── POLLING_OPTIMIZATION_QUICK_SETUP.md     # Polling quick setup
│   │   ├── POLLING_IMPLEMENTATION_SUMMARY.md       # Polling implementation
│   │   └── SCREEN_AWARE_POLLING_COMPLETE.md        # Complete polling docs
│   │
│   ├── UI-Responsiveness/              # 📱 Responsive Design (1 file)
│   │   └── FLUTTER_SCREENUTIL_IMPLEMENTATION_COMPLETE.md
│   │
│   └── Overview/                       # 📋 General Architecture (1 file)
│       └── CLEANUP_SUMMARY.md                      # Architecture cleanup summary
│
├── 03-Features/                        # ✨ Feature Documentation (11 files)
│   │
│   ├── Search/                         # 🔍 Search Feature (3 files)
│   │   ├── SEARCH_IMPROVEMENTS.md                  # Search enhancements
│   │   ├── SEARCH_IMPLEMENTATION.md                # Core search implementation
│   │   └── UNIFIED_SEARCH_IMPLEMENTATION.md        # Unified search system
│   │
│   ├── Payment/                        # 💳 Payment Integration (3 files)
│   │   ├── RAZORPAY_FIX_README.md                  # Razorpay fixes
│   │   ├── RAZORPAY_DEBUG_VS_RELEASE.md            # Debug vs Release config
│   │   └── CURRENCY_CONVERSION_SUMMARY.md          # Currency conversion
│   │
│   ├── Delivery/                       # 🚚 Delivery Tracking (1 file)
│   │   └── delivery_status_flow.md                 # Delivery status flow
│   │
│   ├── UI/                             # 🎨 UI Components (2 files)
│   │   ├── PULL_TO_REFRESH_FIX.md                  # Pull-to-refresh bug fix
│   │   └── PULL_TO_REFRESH_IMPLEMENTATION.md       # Pull-to-refresh feature
│   │
│   ├── Authentication/                 # 🔐 Auth & Access (1 file)
│   │   └── AUTH_GUEST_MODE.md                      # Authentication & guest mode
│   │
│   ├── RealTime/                       # ⚡ Real-time Features (1 file)
│   │   └── SOCKET_IO_CATEGORY_INTEGRATION.md       # Category real-time updates
│   │
│   └── ProductDetails/                 # 🛍️ Product Details (1 file)
│       └── ARCHITECTURE.md                         # Feature architecture
│
├── 04-Development-Guidelines/          # 👨‍💻 Development Standards (4 files)
│   ├── Flutter Coding Standards.md                 # Coding conventions
│   ├── Flutter Mobile Responsiveness using flutter_screenutil.md
│   ├── Linting & Analysis(implementation guide)-Flutter.md
│   └── Pre-Commit Hook Setup Guide.md              # Git hooks setup
│
├── 05-API-Documentation/               # 🔌 API Reference (1 file)
│   └── API Integration Document - BTC Grocery.md   # Complete API docs
│
├── 06-Design/                          # 🎨 Design Resources (1 file)
│   └── figma for uiux.md                           # Figma specifications
│
└── 07-QA-Testing/                      # ✅ Quality Assurance (1 file)
    └── QA.md                                       # QA prompts and audits
```

## 📊 Documentation Statistics

| Category | Files | Purpose |
|----------|-------|---------|
| 01-Getting-Started | 4 | Onboarding and setup |
| 02-Architecture | 18 | Technical architecture |
| 03-Features | 11 | Feature implementations |
| 04-Development-Guidelines | 4 | Coding standards |
| 05-API-Documentation | 1 | Backend API reference |
| 06-Design | 1 | Design resources |
| 07-QA-Testing | 1 | Quality assurance |
| **TOTAL** | **40** | **Complete documentation** |

## 🎯 Quick Access by Topic

### Network & Connectivity
- `02-Architecture/Network/` - HTTP caching, Socket.IO (7 files)
- `03-Features/RealTime/` - Real-time features (1 file)

### Performance Optimization
- `02-Architecture/Performance/` - Polling, screen awareness (4 files)
- `02-Architecture/Network/IF_MODIFIED_SINCE_*` - HTTP caching (5 files)

### Feature Development
- `03-Features/Search/` - Search functionality (3 files)
- `03-Features/Payment/` - Payment integration (3 files)
- `03-Features/Delivery/` - Delivery tracking (1 file)
- `03-Features/ProductDetails/` - Product architecture (1 file)

### UI/UX Development
- `02-Architecture/UI-Responsiveness/` - Responsive design (1 file)
- `03-Features/UI/` - UI components (2 files)
- `06-Design/` - Design resources (1 file)

### Development Setup
- `01-Getting-Started/` - Setup guides (4 files)
- `04-Development-Guidelines/` - Standards & tools (4 files)
- `05-API-Documentation/` - API reference (1 file)

## 🔍 Finding Documentation

### By Category Number
- **01** - Getting Started
- **02** - Architecture
- **03** - Features
- **04** - Development
- **05** - API
- **06** - Design
- **07** - QA

### By Topic
Use the search feature in your code editor:
- Search "SOCKET_IO" for real-time features
- Search "IF_MODIFIED" for HTTP caching
- Search "POLLING" for polling optimization
- Search "RAZORPAY" for payment integration
- Search "SEARCH" for search functionality

## 📝 Document Naming Conventions

- **UPPERCASE_WITH_UNDERSCORES.md** - Technical/implementation docs
- **Title Case with Spaces.md** - Guidelines and standards
- **lowercase_with_underscores.md** - Feature-specific flows
- **README.md** - Overview/index files

## 🔄 Document Relationships

### HTTP Caching Suite (5 files)
1. IF_MODIFIED_SINCE_README.md → Overview
2. IF_MODIFIED_SINCE_ARCHITECTURE.md → Deep dive
3. IF_MODIFIED_SINCE_QUICK_REFERENCE.md → Quick lookup
4. IF_MODIFIED_SINCE_CODE_EXAMPLES.md → Implementation
5. IF_MODIFIED_SINCE_FLOW_DIAGRAMS.md → Visual guide

### Socket.IO Suite (3 files)
1. SOCKET_IO_INTEGRATION.md → Core setup
2. SOCKET_IO_DEBUG_GUIDE.md → Debugging
3. SOCKET_IO_CATEGORY_INTEGRATION.md → Feature example

### Polling Suite (4 files)
1. SCREEN_AWARE_POLLING_GUIDE.md → Guide
2. POLLING_OPTIMIZATION_QUICK_SETUP.md → Quick setup
3. POLLING_IMPLEMENTATION_SUMMARY.md → Summary
4. SCREEN_AWARE_POLLING_COMPLETE.md → Complete reference

### Search Suite (3 files)
1. SEARCH_IMPLEMENTATION.md → Core implementation
2. SEARCH_IMPROVEMENTS.md → Enhancements
3. UNIFIED_SEARCH_IMPLEMENTATION.md → Unified system

## 🎓 Learning Paths

### New Developer Path
1. `01-Getting-Started/README.md`
2. `01-Getting-Started/QUICK_START.md`
3. `04-Development-Guidelines/Flutter Coding Standards.md`
4. `02-Architecture/Network/IF_MODIFIED_SINCE_README.md`

### Feature Developer Path
1. `03-Features/ProductDetails/ARCHITECTURE.md`
2. `02-Architecture/State-Management/DELIVERY_AND_RATING_FLOW.md`
3. `05-API-Documentation/API Integration Document - BTC Grocery.md`

### Performance Engineer Path
1. `02-Architecture/Network/IF_MODIFIED_SINCE_ARCHITECTURE.md`
2. `02-Architecture/Performance/SCREEN_AWARE_POLLING_COMPLETE.md`
3. `02-Architecture/Storage/HIVE implementation.md`

### Backend Integration Path
1. `05-API-Documentation/API Integration Document - BTC Grocery.md`
2. `02-Architecture/Network/SOCKET_IO_INTEGRATION.md`
3. `03-Features/Payment/RAZORPAY_FIX_README.md`

---

**Navigation Tip**: Use this structure to quickly locate documentation. All paths are relative to the `docs/` directory.
