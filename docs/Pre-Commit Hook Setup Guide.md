 **Pre-Commit Hook Setup Guide**

**Objective**

To automatically enforce code quality, structure, and formatting rules *before* any commit is made. This ensures your Flutter project remains consistent, bug-free, and clean

**Prerequisites**

**Purpose:** Ensure your env can run Flutter \+ Git hooks.

**Do:**

* Install **Git for Windows** (includes Git Bash).

* Install **Flutter SDK** and ensure flutter works in both **PowerShell** and **Git Bash**.

**Verify** : flutter \--version  
	 bash \--version  
	 git \--version

—------------------------------------------------------------------------------------------------------------------------

**Repository & Folder Layout**

**Purpose:** Confirm paths and choose a shared place to store hook scripts.

Create new flutter project:  
flutter create \--template=package new\_project

Your repo structure (example):

repo-root/  
        name\_conventions\_lint/            \# your custom lint package   
        new\_project/  
              lib/  
	  android/  
	  .git/  
	        hooks/

Note: Create a .git/hooks/ folder if it doesn’t exist:  
 	mkdir \-p .git/hooks

Create a shell script **setup\_structure.sh** along with the /lib folder:  
/main\_project  
	/pubspec.yaml  
	/lib  
	setup\_structure.sh

below given is the shell script :

\#\!/usr/bin/env bash  
\# \================================================  
\# Flutter Project Folder Scaffold Generator  
\# Creates full modular architecture for clean code  
\# \================================================

set \-e

ROOT="lib"

echo "Creating folder structure under $ROOT..."

\# \-------------------------------  
\# app/  
\# \-------------------------------  
mkdir \-p $ROOT/app/bootstrap  
mkdir \-p $ROOT/app/config  
mkdir \-p $ROOT/app/router/guards  
mkdir \-p $ROOT/app/theme  
mkdir \-p $ROOT/app/localization/arb  
mkdir \-p $ROOT/app/monitoring

touch $ROOT/app/bootstrap/app\_bootstrap.dart  
touch $ROOT/app/bootstrap/hive\_init.dart  
touch $ROOT/app/bootstrap/env\_loader.dart

touch $ROOT/app/config/env.dart  
touch $ROOT/app/config/constants.dart  
touch $ROOT/app/config/feature\_flags.dart

touch $ROOT/app/router/app\_router.dart

touch $ROOT/app/theme/colors.dart  
touch $ROOT/app/theme/typography.dart  
touch $ROOT/app/theme/theme.dart

touch $ROOT/app/localization/l10n.dart

touch $ROOT/app/monitoring/analytics.dart  
touch $ROOT/app/monitoring/crash\_reporting.dart

touch $ROOT/app/app.dart

\# \-------------------------------  
\# core/  
\# \-------------------------------  
mkdir \-p $ROOT/core/network  
mkdir \-p $ROOT/core/storage/hive/adapters  
mkdir \-p $ROOT/core/utils  
mkdir \-p $ROOT/core/widgets  
mkdir \-p $ROOT/core/error

touch $ROOT/core/network/api\_client.dart  
touch $ROOT/core/network/endpoints.dart  
touch $ROOT/core/network/network\_exceptions.dart

touch $ROOT/core/storage/hive/boxes.dart  
touch $ROOT/core/storage/hive/keys.dart  
touch $ROOT/core/storage/secure\_store.dart

touch $ROOT/core/utils/date\_utils.dart  
touch $ROOT/core/utils/validators.dart  
touch $ROOT/core/utils/logger.dart

touch $ROOT/core/widgets/app\_button.dart  
touch $ROOT/core/widgets/app\_card.dart  
touch $ROOT/core/widgets/app\_text\_field.dart  
touch $ROOT/core/widgets/navbar.dart

touch $ROOT/core/error/failure.dart  
touch $ROOT/core/error/error\_view.dart

\# \-------------------------------  
\# features/auth  
\# \-------------------------------  
mkdir \-p $ROOT/features/auth/domain/entities  
mkdir \-p $ROOT/features/auth/domain/repositories  
mkdir \-p $ROOT/features/auth/application/states  
mkdir \-p $ROOT/features/auth/application/providers  
mkdir \-p $ROOT/features/auth/application/usecases  
mkdir \-p $ROOT/features/auth/infrastructure/data\_sources/remote  
mkdir \-p $ROOT/features/auth/infrastructure/data\_sources/local  
mkdir \-p $ROOT/features/auth/infrastructure/repositories  
mkdir \-p $ROOT/features/auth/presentation/screen  
mkdir \-p $ROOT/features/auth/presentation/components

\# Example placeholder files  
touch $ROOT/features/auth/domain/entities/user.dart  
touch $ROOT/features/auth/domain/repositories/auth\_repository.dart  
touch $ROOT/features/auth/application/states/auth\_state.dart  
touch $ROOT/features/auth/application/providers/auth\_provider.dart  
touch $ROOT/features/auth/application/usecases/login.dart  
touch $ROOT/features/auth/infrastructure/data\_sources/remote/auth\_api.dart  
touch $ROOT/features/auth/infrastructure/data\_sources/local/auth\_local\_ds.dart  
touch $ROOT/features/auth/infrastructure/repositories/auth\_repository\_impl.dart  
touch $ROOT/features/auth/presentation/screen/login\_screen.dart  
touch $ROOT/features/auth/presentation/components/header\_section.dart

\# \-------------------------------  
\# features/dashboard  
\# \-------------------------------  
mkdir \-p $ROOT/features/dashboard/domain/entities  
mkdir \-p $ROOT/features/dashboard/domain/repositories  
mkdir \-p $ROOT/features/dashboard/application/states  
mkdir \-p $ROOT/features/dashboard/application/providers  
mkdir \-p $ROOT/features/dashboard/application/usecases  
mkdir \-p $ROOT/features/dashboard/infrastructure/data\_sources/remote  
mkdir \-p $ROOT/features/dashboard/infrastructure/data\_sources/local  
mkdir \-p $ROOT/features/dashboard/infrastructure/repositories  
mkdir \-p $ROOT/features/dashboard/presentation/screen  
mkdir \-p $ROOT/features/dashboard/presentation/components

touch $ROOT/features/dashboard/presentation/screen/home\_screen.dart

\# \-------------------------------  
\# features/profile  
\# \-------------------------------  
mkdir \-p $ROOT/features/profile/domain/entities  
mkdir \-p $ROOT/features/profile/domain/repositories  
mkdir \-p $ROOT/features/profile/application/states  
mkdir \-p $ROOT/features/profile/application/providers  
mkdir \-p $ROOT/features/profile/application/usecases  
mkdir \-p $ROOT/features/profile/infrastructure/data\_sources/remote  
mkdir \-p $ROOT/features/profile/infrastructure/data\_sources/local  
mkdir \-p $ROOT/features/profile/infrastructure/repositories  
mkdir \-p $ROOT/features/profile/presentation/screen  
mkdir \-p $ROOT/features/profile/presentation/components

touch $ROOT/features/profile/presentation/screen/profile\_screen.dart

\# \-------------------------------  
\# features/common  
\# \-------------------------------  
mkdir \-p $ROOT/features/common/pagination  
mkdir \-p $ROOT/features/common/attachments

\# \-------------------------------  
\# entry files  
\# \-------------------------------  
touch $ROOT/main.dart  
touch $ROOT/globals.dart

echo "Folder structure created successfully\!"

Run the below comments to create the folder structure in **GIT BASH:**

1\. Navigate to the project folder, inside run below to make the shell script executable:  
	chmod \+x setup\_structure.sh  
2\. Then run to create the folder  
	./setup\_structure.sh

—------------------------------------------------------------------------------------------------------------------------

**Add Required Packages**

flutter pub add \--dev very\_good\_analysis  
flutter pub add \--dev flutter\_lints  
flutter pub add \--dev custom\_lint  
flutter pub get

If you have your own name\_conventions\_lint plugin:  
\# project\_app/pubspec.yaml

dev\_dependencies:  
  naming\_conventions\_lint:  
    path: ../naming\_conventions\_lint

—-------------------------------------------------------------------------------------------------------------

**Create analysis\_options.yaml**

In project\_app/ root:

include: package:flutter\_lints/flutter.yaml

analyzer:  
  plugins:  
    \- custom\_lint  
  exclude:  
    \- "\*\*/\*.g.dart"  
    \- "\*\*/\*.freezed.dart"  
    \- "build/\*\*"  
  errors:  
    avoid\_print: error  
    prefer\_const\_constructors: error  
    require\_trailing\_commas: error  
linter:  
  rules:  
    camel\_case\_types: true  
    file\_names: true  
    prefer\_const\_constructors: true  
    require\_trailing\_commas: true  
    avoid\_print: true  
    use\_key\_in\_widget\_constructors: true

 Note: This configures your basic lint \+ plugin integration.

Your custom rules will now run automatically when dart run custom\_lint executes.

—-------------------------------------------------------------------------------------------------------------

**Create Pre-Commit Hook File**

Run this inside **Git Bash**  
	cd .git  
	touch hooks/pre-commit

Then open .git/hooks/pre-commit in VS Code and paste the full script below.

—---------------------------------------------------------------------------------------------

**The Complete Pre-Commit Hook Script**

\#\!/usr/bin/env bash  
\# \--- Flutter & Dart PATH setup (Windows safe) \---  
\# Adjust the path to your actual Flutter SDK root if needed  
export PATH="$PATH:/c/Users/LENOVO/flutterwindows/flutter/bin:/c/Users/LENOVO/flutterwindows/flutter/bin/cache/dart-sdk/bin"  
\# \============================================  
\# temple\_app pre-commit hook (Windows \+ Flutter)  
\# \============================================

RED="\\033\[0;31m"; GREEN="\\033\[0;32m"; YELLOW="\\033\[1;33m"; BLUE="\\033\[0;34m"; NC="\\033\[0m"  
ok(){ echo \-e "${GREEN}? $1${NC}"; }  
err(){ echo \-e "${RED}? $1${NC}"; }  
warn(){ echo \-e "${YELLOW}? $1${NC}"; }  
header(){ echo \-e "\\n${BLUE}??????????????????????????????????????????????${NC}\\n${BLUE}$1${NC}\\n${BLUE}??????????????????????????????????????????????${NC}"; }

header "Running temple\_app Pre-commit Checks"

\# Fetch staged files  
STAGED\_FILES=$(git diff \--cached \--name-only \--diff-filter=ACM)  
if \[ \-z "$STAGED\_FILES" \]; then  
  warn "No files staged for commit."  
  exit 0  
fi

\# 1?? Format  
\# \=======================================================  
\# 1\) Ensuring UTF-8 Encoding & Formatting Dart files  
\# \=======================================================  
header "1) Formatting Dart files"

DART\_FILES=$(echo "$STAGED\_FILES" | grep '\\.dart$' || true)  
if \[ \-n "$DART\_FILES" \]; then  
  echo "Ensuring UTF-8 encoding & formatting Dart files..."

  FORMATTER="/c/Users/LENOVO/flutterwindows/flutter/bin/cache/dart-sdk/bin/dart.exe"

  \# Convert files to UTF-8 if they aren't already  
  for f in $DART\_FILES; do  
    \# Detect encoding using 'file'  
    encoding=$(file \-bi "$f" | grep \-o 'charset=.\*' | cut \-d= \-f2)  
    if \[ "$encoding" \!= "utf-8" \]; then  
      echo " → Converting $f ($encoding → UTF-8)"  
      iconv \-f "$encoding" \-t utf-8 "$f" \-o "$f.tmp" && mv "$f.tmp" "$f"  
    fi  
  done

  \# Format each file safely  
  FORMAT\_FAIL=false  
  for f in $DART\_FILES; do  
    echo " → Checking $f"  
    "$FORMATTER" format "$f" \>/dev/null 2\>&1  
    if \[ $? \-ne 0 \]; then  
      echo "   ⚠ Failed to format: $f"  
      FORMAT\_FAIL=true  
    else  
      git add "$f"  
    fi  
  done

  if \[ "$FORMAT\_FAIL" \= true \]; then  
    err "dart format failed on one or more files (check encoding or syntax)"  
    exit 1  
  fi

  ok "Formatted & re-staged all Dart files"  
else  
  warn "No Dart files found to format"  
fi

\# 2?? Flutter analyze  
header "2) Flutter analyze"  
flutter analyze \>/dev/null 2\>&1  
if \[ $? \-ne 0 \]; then err "Analyzer found issues. Run 'flutter analyze'."; exit 1; fi  
ok "Analyzer passed"

\# 3?? custom\_lint  
header "3) Running custom\_lint"  
dart run custom\_lint \>/dev/null 2\>&1  
if \[ $? \-ne 0 \]; then err "custom\_lint found issues"; exit 1; fi  
ok "custom\_lint passed"

\# 4?? Debug prints check  
header "4) Checking for debug prints / TODOs"  
DEBUG\_FOUND=false  
for f in $DART\_FILES; do  
  if grep \-E "print\\(|debugPrint\\(" "$f" | grep \-v "^\[\[:space:\]\]\*//" \>/dev/null 2\>&1; then  
    echo " ? $f"  
    DEBUG\_FOUND=true  
  fi  
done  
if \[ "$DEBUG\_FOUND" \= true \]; then err "Remove print()/debugPrint() before committing"; exit 1; fi  
ok "No debug prints"

\# 5?? Folder Structure Validation  
header "5) Validating folder structure"

ALLOWED\_PATHS=(  
  "^lib/app/"  
  "^lib/app/bootstrap/"  
  "^lib/app/config/"  
  "^lib/app/router/"  
  "^lib/app/router/guards/"  
  "^lib/app/theme/"  
  "^lib/app/localization/"  
  "^lib/app/localization/arb/"  
  "^lib/app/monitoring/"  
  "^lib/core/"  
  "^lib/core/network/"  
  "^lib/core/storage/"  
  "^lib/core/storage/hive/"  
  "^lib/core/storage/hive/adapters/"  
  "^lib/core/utils/"  
  "^lib/core/widgets/"  
  "^lib/core/error/"  
  "^lib/features/"  
  "^lib/features/\[a-z0-9\_\]+/domain/"  
  "^lib/features/\[a-z0-9\_\]+/application/"  
  "^lib/features/\[a-z0-9\_\]+/infrastructure/"  
  "^lib/features/\[a-z0-9\_\]+/presentation/"  
  "^lib/features/common/"  
  "^lib/main.dart$"  
  "^lib/globals.dart$"  
)  
INVALID\_FILES=()  
for file in $STAGED\_FILES; do  
  if \[\[ "$file" \== lib/\* \]\]; then  
    VALID=false  
    for pattern in "${ALLOWED\_PATHS\[@\]}"; do  
      if \[\[ "$file" \=\~ $pattern \]\]; then VALID=true; break; fi  
    done  
    if \[ "$VALID" \= false \]; then INVALID\_FILES+=("$file"); fi  
  fi  
done  
if \[ ${\#INVALID\_FILES\[@\]} \-gt 0 \]; then  
  err "Folder structure violation:"  
  for f in "${INVALID\_FILES\[@\]}"; do echo "  ? $f"; done  
  exit 1  
fi  
ok "Folder structure valid"

\# 6?? Dart file naming validation  
header "6) Validating Dart file names"

declare \-A ALLOWED\_DART\_FILES  
ALLOWED\_DART\_FILES\["lib/app/bootstrap/"\]="app\_bootstrap.dart hive\_init.dart env\_loader.dart"  
ALLOWED\_DART\_FILES\["lib/app/config/"\]="env.dart constants.dart feature\_flags.dart"  
ALLOWED\_DART\_FILES\["lib/app/router/"\]="app\_router.dart"  
ALLOWED\_DART\_FILES\["lib/app/theme/"\]="colors.dart typography.dart theme.dart"  
ALLOWED\_DART\_FILES\["lib/app/localization/"\]="l10n.dart"  
ALLOWED\_DART\_FILES\["lib/core/network/"\]="api\_client.dart endpoints.dart network\_exceptions.dart"  
ALLOWED\_DART\_FILES\["lib/core/storage/hive/"\]="boxes.dart keys.dart"  
ALLOWED\_DART\_FILES\["lib/core/utils/"\]="date\_utils.dart validators.dart logger.dart"  
ALLOWED\_DART\_FILES\["lib/core/error/"\]="failure.dart error\_view.dart"

INVALID\_DART\_FILES=()  
for file in $DART\_FILES; do  
  for folder in "${\!ALLOWED\_DART\_FILES\[@\]}"; do  
    if \[\[ "$file" \== "$folder"\* \]\]; then  
      filename=$(basename "$file")  
      allowed\_list="${ALLOWED\_DART\_FILES\[$folder\]}"  
      if \! echo "$allowed\_list" | grep \-qw "$filename"; then  
        INVALID\_DART\_FILES+=("$file")  
      fi  
    fi  
  done  
done  
if \[ ${\#INVALID\_DART\_FILES\[@\]} \-gt 0 \]; then  
  err "Invalid Dart files for their folders:"  
  for f in "${INVALID\_DART\_FILES\[@\]}"; do echo "  ? $f"; done  
  exit 1  
fi  
ok "Dart file names validated successfully"

\# 7 Riverpod State Mutation Violation Check  
header "7) Checking for illegal .state mutations"

VIOLATION\_FOUND=false

for f in $DART\_FILES; do  
  if grep \-E "\\.state\\s\*=" "$f" \>/dev/null 2\>&1; then  
      
    \# allow if the file contains a StateNotifier class definition  
    if \! grep \-E "class\\s+\[A-Za-z0-9\_\]+\\s+extends\\s+StateNotifier" "$f" \>/dev/null 2\>&1; then  
      echo " ⚠ Illegal state mutation in: $f"  
      VIOLATION\_FOUND=true  
    fi  
  fi  
done

if \[ "$VIOLATION\_FOUND" \= true \]; then  
  err "Direct .state mutations outside StateNotifier are NOT allowed."  
  exit 1  
fi

ok "No direct .state mutations found"

header "? All Checks Passed"  
ok "Proceeding with commit..."  
exit 0

—------------------------------------------------------------------------------------------------------------------------------------

**Make It Executable**

In Git Bash:

	chmod \+x .git/hooks/pre-commit

—-------------------------------------------------------------------------------------------------------------

**Test the Hook**

Test the hook:  
   	git add .

git commit \-m "Test hook"

git push

—------------------------------------------------------------------------------------------------------------------------

**Common Issues & Fixes**  
**1\. dart format failed**

**Symptoms**: You’ll see something like below:  
	⚠ Failed to format: lib/temp/test4.dart  
	✗ dart format failed on one or more files (check encoding or syntax)

**Cause**

This usually happens because:

* The Dart file is **not saved in UTF-8 encoding** (common on Windows when files are created via PowerShell, Notepad, or older editors).

* The file has **hidden characters or bad line endings** (CRLF instead of LF).

 **Fix**

1. **Convert the file(s) to UTF-8 automatically** using PowerShell:

	Get-ChildItem lib/\*\*/\*.dart | ForEach-Object {  
	  $content \= Get-Content $\_.FullName \-Raw  
  	\[IO.File\]::WriteAllText($\_.FullName, $content, \[Text.Encoding\]::UTF8)}

      2 **.  Re-add and commit again:**

git add lib/\*\*/\*.dart

git commit \-m "Re-try after UTF-8 fix"

**Verification in bash:** /c/Users/LENOVO/flutterwindows/flutter/bin/cache/dart-sdk/bin/dart.exe format \<yourfile.dart\>

**2\. Analyzer found issues**

**Symptoms**

You’ll see something like: 

✗ Analyzer found issues. Run 'flutter analyze'.

**Cause**

The Flutter analyzer found syntax errors, type mismatches, or unused imports.

 **Fix**

1. Run the analyzer manually to see the exact issues:  
    flutter analyze  
2. Review the output — examples:  
   	 warning • Unused import: 'package:flutter/material.dart'  
   	 error • The method 'abc' isn't defined for the class 'MyWidget'  
3. Fix each issue in your Dart files.

4. Re-run:  
   	 flutter analyze

 	until you see:  
		No issues found\!

5. Then commit again.

**Verification**  
 Commit should now show:  
	✓ Analyzer passed

 **3\. custom\_lint not found or custom\_lint found issues**

 **Symptoms**: You’ll see something like:

✗ dart run custom\_lint: command not found

Or ✗ custom\_lint found issues

**Cause**

Either:

* The custom\_lint package isn’t installed in dev\_dependencies, or

* You have rule violations (naming, imports, etc.).

 **Fix**

1. Open your pubspec.yaml and ensure this exists:  
    dev\_dependencies:  
           custom\_lint: ^0.6.4  
2. Install it:  
    dart pub get  
3. Run the linter manually:  
   	 dart run custom\_lint  
4. Fix the violations shown in the output (e.g., rename classes, remove bad imports).

**Verification**  
 When you run dart run custom\_lint, you should see:

All checks passed successfully\!

Then commit again.

**4\. Permission denied when running hook**

**Symptoms**  
	fatal: cannot run .git/hooks/pre-commit: Permission denied

**Cause**

The hook file doesn’t have *execute permission* on Windows Git Bash.

**Fix**

Grant execute permission to the hook:  
 	chmod \+x .git/hooks/pre-commit

**Verification**  
 Run:  ls \-l .git/hooks/pre-commit

You should see:

\-rwxr-xr-x 1 user user  5000 Oct 21  pre-commit

(x means executable.)  
 Then retry your commit.

**5\. fatal: detected dubious ownership in repository**

**Symptoms**

fatal: detected dubious ownership in repository at 'C:/Users/LENOVO/nexotech/Temple\_App-edwin'

**Cause**

Git detects that the folder owner doesn’t match your current user.  
 This is a **Git security feature** to prevent running malicious hooks on unsafe directories.

 **Fix**

Mark your project as safe for Git:

git config \--global \--add safe.directory "C:/Users/LENOVO/nexotech/Temple\_App-edwin"

**Verification**  
 Run your commit again — the warning will disappear.

