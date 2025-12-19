# Grocery App Setup Guide

## Prerequisites
- Flutter SDK 3.9.2 or higher
- Git
- Git Bash (for Windows users)

## Initial Setup

### Step 1: Clone the Main Repository
```bash
git clone <your-grocery-app-repo-url>
cd Grocery_app_BTC_FRESH
```

### Step 2: (Optional) Clone the Naming Conventions Lint Package

**Skip this step if you're using Git dependency** (default setup).

If you want a local copy for development/modification:
```bash
cd ..
git clone https://github.com/Abin56/naming_conventions_lint.git
cd Grocery_app_BTC_FRESH
```

### Step 3: Install Dependencies
```bash
flutter pub get --no-example
```

### Step 4: Install Pre-commit Hook
Copy the pre-commit script to git hooks directory:
```bash
cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**For Windows users (PowerShell):**
```powershell
Copy-Item scripts/pre-commit -Destination .git/hooks/pre-commit
```

### Step 5: Verify Setup
Run flutter analyze to verify lint rules are working:
```bash
flutter analyze
```

You should see:
```
Analyzing Grocery_app_BTC_FRESH...
No issues found! (ran in X.Xs)
```

## Directory Structure
```
Grocery/
├── Grocery_app_BTC_FRESH/          # Main Flutter app
│   ├── pubspec.yaml
│   ├── analysis_options.yaml
│   ├── custom_lint.yaml
│   ├── scripts/
│   │   └── pre-commit              # Pre-commit hook script
│   └── .git/
│       └── hooks/
│           └── pre-commit          # Installed hook
└── naming_conventions_lint/        # Custom lint package
    ├── pubspec.yaml
    ├── lib/
    │   ├── naming_conventions_lint.dart
    │   └── src/
    │       └── plugin.dart
```

## Making Commits

The pre-commit hook runs automatically before each commit and checks:

1. **Dart Formatting** - Auto-formats all dart files
2. **Flutter Analyze** - Checks for analysis issues
3. **Custom Lint** - Runs custom naming convention rules
4. **Debug Prints** - Checks for print() and debugPrint() statements

### Example Commit
```bash
git add .
git commit -m "first commit"
```

The hook will automatically:
- ✅ Format your code
- ✅ Run analyzer checks
- ✅ Run custom lint rules
- ✅ Check for debug prints

If any check fails, the commit will be blocked. Fix the issues and try again.

## Useful Commands

### Run Specific Checks
```bash
# Format dart files
dart format .

# Run analyzer
flutter analyze

# Run custom lint
dart run custom_lint

# Check for debug prints
grep -r "print(" lib/
```

### Clean Setup (if needed)
```bash
flutter clean
flutter pub get --no-example
flutter analyze
```

## Troubleshooting

### Pre-commit hook not running?
**Windows (Git Bash):**
- Use **Git Bash** terminal, not PowerShell or CMD
- Ensure `.git/hooks/pre-commit` file exists and is executable

**Verify hook is installed:**
```bash
ls -la .git/hooks/pre-commit
```

### Custom lint not working?
Ensure both directories exist:
```bash
# Main app
ls pubspec.yaml

# Lint package
ls ../naming_conventions_lint/pubspec.yaml
```

### Can't run dart commands?
```bash
# Ensure Flutter/Dart tools are in PATH
flutter doctor
```

## Configuration Files

### pubspec.yaml
- Contains `naming_conventions_lint` as a path dependency: `path: ../naming_conventions_lint`
- Contains `custom_lint` package for running custom rules

### analysis_options.yaml
- Includes Flutter lint configuration
- Enables `custom_lint` plugin
- Defines lint rules (camelCase, file_names, avoid_print, etc.)

### custom_lint.yaml
- Optional configuration file for custom lint rules
- Auto-discovers rules from installed packages

### scripts/pre-commit
- Git hook that runs checks before each commit
- Automatically installed to `.git/hooks/pre-commit`

## Team Collaboration

### For New Team Members
1. Clone the main repository
2. Follow **Initial Setup** steps 2-5 above
3. Verify with `flutter analyze`

### If Custom Lint Package is Updated
```bash
cd ../naming_conventions_lint
git pull origin main
cd ../Grocery_app_BTC_FRESH
flutter pub get --no-example
```
