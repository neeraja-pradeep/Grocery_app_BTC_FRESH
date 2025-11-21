We do the complete code QA and audit via claude code. So here are the prompts which we used for the code auditing. This may be of multiple parts. Analyse this to generate the codes that passes the below tests:

Prompt 1
--------
You are a Flutter architect specializing in Riverpod. Audit this codebase for state management violations.

### CRITICAL VIOLATIONS
1. Direct .state mutations outside owning StateNotifier
2. ref.watch() in callbacks/event handlers/async functions
3. Missing autoDispose on temporary UI state (page index, selected dates, form fields)
4. FutureProvider used for mutations (add/update/delete)
5. BuildContext passed to StateNotifier/Provider
6. Business logic in Widget build methods
7. ref.invalidate() called inside provider's own body
8. Repositories instantiated directly instead of via provider
9. Circular provider dependencies
10. Provider families missing autoDispose for dynamic data
11. Navigation/SnackBar/Dialog logic in providers/notifiers
12. UI-specific code in business logic layer

### HIGH PRIORITY
13. ConsumerWidget used when StatelessWidget sufficient
14. Inconsistent provider naming (not following {feature}RepositoryProvider pattern)
15. Global providers incorrectly marked autoDispose
16. Repositories containing business logic
17. UI widgets directly accessing data sources
18. Models containing business logic methods

## OUTPUT FORMAT

For each issues found, provide:

1. **File Path**
2. **Severity**: CRITICAL | HIGH | MEDIUM | LOW
3. **Issue Description**: What's wrong and why it matters
4. **Code Snippet**: Show the problematic code
5. **Fix**: Explain how to fix it with example code
6. **Impact**: What breaks if this isn't fixed

Priority order:
1. All files in /lib/providers/
2. All files in /lib/repositories/
3. All files touching Hive (search for "Hive.box")
4. All ConsumerWidget and ConsumerStatefulWidget files
5. Files with StateNotifier implementations

## Deliverables

1. **Executive Summary**: 
   - Total files reviewed
   - Critical issues count
   - High priority issues count
   - Top 3 systemic problems

2. **Detailed Issue Log**: 
   - All issues with severity, location, fix

3. **Refactoring Recommendations**:
   - Architectural improvements needed
   - Priority order for fixes

4. **Technical Debt Score**: 
   - Rate codebase 1-10 (10 = excellent)
   - Justify the score

Start with the providers/ and repositories/ directories first.

Start audit now.

Prompt 2
---------
You are a Flutter security architect. Audit this codebase for data persistence and security vulnerabilities.

### CRITICAL VIOLATIONS
1. Hive.openBox() called inside repository methods
2. Hive boxes not closed in autoDispose providers
3. Hive imported in UI layer (screens/widgets)
4. Hive operations in build() methods
5. android:allowBackup setting in AndroidManifest.xml
6. Auth tokens in plain SharedPreferences
7. Logout missing: token clearing
8. Logout missing: Hive box deletion
9. Logout missing: FirebaseAuth.instance.signOut()
10. Auto-login without token validation
11. Auto-login without null checks on Hive data
12. Login not clearing previous user's data
13. Sensitive data (tokens/passwords/OTPs) in print statements
14. Missing backup_rules.xml when allowBackup=true
15. Hardcoded API keys/secrets/credentials
16. Exposed Firebase configuration in version control

### HIGH PRIORITY
17. TypeAdapters not registered before box access
18. Synchronous Hive operations on large datasets
19. Hive boxes not deleted on logout
20. Logout not using pushNamedAndRemoveUntil
21. Logout not invalidating providers
22. Firebase initialization order issues
23. Firebase authentication error handling missing
24. Firebase listeners not disposed

## SPECIAL FOCUS
- Trace complete logout flow (show all steps)
- Trace auto-login flow (show validation checks)
- Check AndroidManifest.xml backup configuration
- List all token storage locations

## OUTPUT FORMAT

For each violation:
**File:** path/to/file.dart:line_number
**Severity:** CRITICAL | HIGH
**Security Risk:** [Impact description]
**Code:**
```dart
[Show problematic code]
```

## ANDROID MANIFEST CHECK
**Current allowBackup setting:**
**Backup rules file exists:**
**Assessment:**

## TOKEN STORAGE INVENTORY
List all locations where auth tokens are stored/retrieved/cleared.

Start audit now.

Prompt 3
----------
You are a Flutter performance architect. Audit this codebase for error handling and performance issues.

### CRITICAL VIOLATIONS
1. Async providers without try-catch or AsyncValue.guard()
2. Heavy operations in build() methods (JSON parsing, file I/O, calculations)

### HIGH PRIORITY
3. Async operations returning null without error indication
4. Network errors without retry logic for critical operations
5. Widget rebuilds excessively (check with DevTools)
6. Large lists not using builder pattern
7. Unnecessary widget rebuilds
8. Dependencies without version constraints (using 'any')

### MEDIUM PRIORITY
9. Generic catch blocks without logging
10. APK size >50MB
11. Unoptimized images/assets (large files, wrong formats)
12. Multiple ABIs bundled in single APK
13. Debug symbols not stripped in release builds
14. Unused dependencies in pubspec.yaml
15. Duplicate functionality across packages
16. Heavy packages without lighter alternatives

## PERFORMANCE ANALYSIS
Run these checks:
1. Identify all heavy operations in build() methods
2. List all large lists not using .builder pattern
3. Check pubspec.yaml for optimization opportunities
4. Identify providers that rebuild frequently

## OUTPUT FORMAT

For each issue:
**File:** path/to/file.dart:line_number
**Severity:** CRITICAL | HIGH | MEDIUM
**Performance Impact:** [Description]
**Code:**
```dart
[Show problematic code]
```

## DEPENDENCY REPORT
- Total dependencies: X
- Unused dependencies: [list]
- Version constraint issues: [list]
- Heavy packages (>5MB): [list]

Start audit now.

Prompt 4
---------
You are a Flutter code quality auditor. Audit this codebase for code quality and deployment readiness.

### CRITICAL VIOLATIONS
1. App crashes after uninstall/reinstall
2. Auto-login persists to wrong user after reinstall
3. User B sees User A's data when switching accounts
4. Debug/test credentials in production build
5. flutter analyze has errors/warnings
6. flutter test has failing tests
7. Critical user flows untested on physical device
8. Version number not incremented for release

### HIGH PRIORITY
9. Memory leaks (navigate 20+ times, check DevTools)
10. App fails with internet OFF
11. App doesn't handle low memory situations
12. Migration logic missing for breaking changes
13. Old data formats not handled in new versions
14. Corrupted backup data not handled
15. Git commit contains unrelated files
16. CHANGELOG.md not updated
17. App not tested on multiple Android versions
18. Firebase listeners not disposed

### MEDIUM PRIORITY
19. Excessive print statements
20. Magic numbers and hardcoded delays
21. Missing documentation on complex providers
22. Unused imports and providers
23. Duplicate logic across files
24. TODO/FIXME in production code
25. App crashes after background for extended period
26. App store metadata outdated
27. dart format not applied

## TESTING VALIDATION
Check if these manual tests are documented:
- Uninstall/reinstall flow
- User switching flow
- Internet OFF scenarios
- Low memory scenarios
- Background/foreground transitions

## OUTPUT FORMAT

For each issue:
**Category:** Testing | Code Quality | Deployment
**Severity:** CRITICAL | HIGH | MEDIUM
**Issue:** [Description]
**Location:** [If applicable]

## DEPLOYMENT READINESS SCORE
Rate 1-10 based on:
- Critical issues blocking deployment
- Testing coverage
- Code quality
- Documentation

## RECOMMENDED ACTIONS
List top 5 actions before deployment.

Start audit now.

Prompt 5
----------
Comming soon
