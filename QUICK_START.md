# Quick Start - Setup in 5 Steps

## For New Developers

### 1️⃣ Clone main repository
```bash
git clone <your-app-url>
cd Grocery_app_BTC_FRESH
```

### 1️⃣b (Optional) Clone lint package locally
**Only if you want to modify the lint rules locally:**
```bash
cd ..
git clone https://github.com/Abin56/naming_conventions_lint.git
cd Grocery_app_BTC_FRESH
```
⚠️ If you skip this, git dependency will download from GitHub automatically.

### 2️⃣ Get dependencies
```bash
flutter pub get --no-example
```

### 3️⃣ Install pre-commit hook
**Git Bash or macOS/Linux:**
```bash
cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**Windows PowerShell:**
```powershell
Copy-Item scripts/pre-commit -Destination .git/hooks/pre-commit
```

### 4️⃣ Verify setup
```bash
flutter analyze
```

Expected output: `No issues found!`

### 5️⃣ Start developing
```bash
# Make your changes
git add .
git commit -m "your message"
# Hook runs automatically ✅
```

---

## Key Commands

| Command | Purpose |
|---------|---------|
| `flutter analyze` | Check code issues |
| `dart run custom_lint` | Run custom lint rules |
| `dart format .` | Auto-format code |
| `git commit -m "msg"` | Commit (hook runs automatically) |

---

## What the Hook Does

When you run `git commit`:
1. ✅ Formats all Dart files
2. ✅ Runs Flutter analyzer
3. ✅ Runs custom lint rules
4. ✅ Checks for debug prints
5. 🚀 If all pass → commit succeeds

If any check fails → commit blocked (fix and try again)

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Hook not running | Use **Git Bash**, not PowerShell |
| `naming_conventions_lint` not found | Clone it: `cd .. && git clone https://github.com/Abin56/naming_conventions_lint.git` |
| `flutter analyze` fails | Run `flutter pub get` and try again |

---

## File Locations

```
Grocery/
├── Grocery_app_BTC_FRESH/
│   ├── scripts/pre-commit ← Original script
│   └── .git/hooks/pre-commit ← Installed here
└── naming_conventions_lint/ ← Required
```
