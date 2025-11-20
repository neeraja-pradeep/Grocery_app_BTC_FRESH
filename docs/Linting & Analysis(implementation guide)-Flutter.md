**What is “Linting & Analysis”?**  
Linting means automated code quality checking — a process that analyzes your Dart and Flutter code for:

* potential bugs,

* bad practices,

* style inconsistencies, and

* violations of your team’s agreed-upon coding standards.

analysis\_options.yaml is the configuration file where you define these rules.  
 When you run dart analyze, Flutter uses this file to decide what’s allowed or not in your code.  
So think of it as your project’s rulebook for clean, consistent, bug-free code.

**Why It’s Required?**

- Early Bug Detection

The analyzer catches common issues before runtime, like:

* null safety mistakes,

* unused imports,

* unreachable code,

* wrong return types, etc.  
   This prevents crashes before you even test the app.

- Improved Maintainability

When 10+ developers work on multiple projects, consistent code makes:

* onboarding new interns easier,

* debugging faster,

* refactoring safer.

- Automated Quality Gate

In CI (Continuous Integration), you can run dart analyze automatically on every pull request.  
If someone introduces a lint violation, the build fails — preventing messy code from merging.

**Implementation Guide for every project:**

**1\. The lint plugin package (sits NEXT to your app)**  
	From your workspace folder (the parent of Main\_project/):   
     	You should have:  
		/Main\_project  
/naming\_conventions\_lints

**2\. You will be seeing dependencies:**  
	Open naming\_conventions\_lints/pubspec.yaml :

name: naming\_conventions\_lint  
description: "A new Flutter package project."  
version: 0.0.1  
publish\_to: "none"  
homepage:

environment:  
  sdk: ^3.8.1  
  flutter: "\>=1.17.0"

dependencies:  
  flutter:  
    sdk: flutter  
  analyzer: ^6.4.0  
  custom\_lint\_builder: ^0.6.4  
  path: ^1.9.0

dev\_dependencies:  
  flutter\_test:  
    sdk: flutter  
  flutter\_lints: ^5.0.0

**3\. plugin entry points**

- **lib/naming\_conventions\_lint.dart:**  
  	import 'package:custom\_lint\_builder/custom\_lint\_builder.dart';  
  import 'src/plugin.dart';

  PluginBase createPlugin() \=\> NamingConventionsPlugin();

- **lb/src/plugin.dart:**

     	import 'package:custom\_lint\_builder/custom\_lint\_builder.dart';  
import 'rules/naming\_conventions\_entry\_rule.dart';

class NamingConventionsPlugin extends PluginBase {  
 	  @override  
  	   List\<LintRule\> getLintRules(CustomLintConfigs \_) \=\> \[  
        		NamingConventionsEntryRule(),  
      		\];  
}

- **lib/src/rules/naming\_conventions\_base.dart:** this contains all the rules class files

- l**ib/src/rules/naming\_conventions\_entry\_rule.dart**

**Explanation of each rule class:**  
**Overview**  
Each rule class extends  
abstract class NamingConventionRule extends SimpleAstVisitor\<void\>

and uses:  
reportFormatted({  
  	required AstNode node,  
  	required String rule,  
  	required String whatFailed,  
  	required String why,  
  	required String action,  
});

to generate the error message and correction message.

Each lint will appear like this in your terminal/editor:  
\[Naming Convention: \<rule\>\] \<whatFailed\> failed validation in "\<file\>". \<why\>  
→ \<action\>

**Complete Rule List (with Purpose, Error, and Fix)**

| Rule Class Name | Purpose (What it checks) | Example Error Message (What & Why) | Suggested Correction (Action) |
| :---- | :---- | :---- | :---- |
| ScreenNamingRule | Ensures classes/files related to screens end with Screen and file ends with \_screen.dart. | \[Naming Convention: ScreenNamingRule\] Class "Home" failed validation. Screen classes must end with "Screen". | Rename class to HomeScreen and file to home\_screen.dart. |
| SectionNamingRule | Ensures section widgets follow \_section.dart and Section suffix. | File/class naming mismatch. | Rename to my\_section.dart / MySection. |
| CardTileNamingRule | Enforces PascalCase for Card/Tile widgets. | Class not PascalCase. | Rename class to PascalCase (e.g., UserCard). |
| ProviderNamingRule | Enforces all provider variables end with Provider and are in camelCase. | userprovider or user\_Provider. | Rename to userProvider. |
| StateNamingRule | Ensures classes in \_state.dart end with State. | Class name doesn’t end with State. | Rename to MyWidgetState. |
| UseCaseNamingRule | Ensures file and class use same verb (e.g., FetchUser → fetch\_user.dart). | Class doesn’t start with matching verb. | Rename class to FetchUser. |
| RepositoryNamingRule | Interface repo classes must end with Repository. | Class UserRepo invalid. | Rename to UserRepository. |
| RepositoryImplNamingRule | Implementation repo classes must end with RepositoryImpl. | Class UserImpl invalid. | Rename to UserRepositoryImpl. |
| RemoteDataSourceNamingRule | Classes in \_api.dart must end with Api. | File/class mismatch. | Rename class to UserApi. |
| LocalDataSourceNamingRule | Classes in \_local\_ds.dart must end with LocalDs. | Class not ending properly. | Rename to UserLocalDs. |
| AdapterNamingRule | Enforces \_adapter.dart → Adapter suffix. | class UserAdptr. | Rename to UserAdapter. |
| CoreWidgetNamingRule | Files starting app\_ must have class names starting with App. | Class Button in app\_button.dart. | Rename to AppButton. |
| TestNamingRule | \_test.dart files must be inside /test folder. | File in wrong folder. | Move file to /test directory. |
| UtilsNamingRule | Enforces PascalCase for utility classes. | class userutils. | Rename to UserUtils. |
| GenericWidgetNamingRule | Widgets must end with Widget if file contains “widget”. | class Button in my\_widget.dart. | Rename to MyWidget. |
| PrivateClassNamingRule | Private classes only allowed for \_MyState. | \_MyHelper invalid. | Rename to MyHelper. |
| ModelNamingRule | \_model.dart → must end with Model. | class User. | Rename to UserModel. |
| DtoNamingRule | \_request.dart or \_response.dart must end with Request or Response. | UserReq. | Rename to UserRequest. |
| DerivedProviderNamingRule | Derived providers start with current \+ PascalCase. | currentuserProvider. | Rename to currentUserProvider. |
| BooleanProviderNamingRule | Boolean providers must start with is and end with Provider. | userActive. | Rename to isUserActiveProvider. |
| RepositoryProviderNamingRule | Repository providers should match a repository file. | Misplaced provider file. | Move or rename accordingly. |
| ServiceProviderNamingRule | Service providers must correspond to \*\_service.dart. | Wrong directory or naming. | Rename to UserServiceProvider. |
| ModelRequiredMethodsRule | Models must have fromJson, toJson, and copyWith. | Missing method(s). | Add missing method definitions. |
| DtoRequiredMethodsRule | DTOs must have fromJson and toJson. | Missing toJson. | Add required methods. |
| ModelDtoFieldImmutabilityRule | Model/DTO fields must be final. | Mutable field found. | Add final keyword. |
| HiveBoxesDeclarationRule | HiveBoxes constants: static const String, camelCase identifier, snake\_case value. | Non-const or wrong format. | Fix declaration to static const String userBox \= 'user\_box';. |
| HiveOpenBoxUsageRule | Prevent magic strings in Hive.openBox. | Hive.openBox('user\_box'). | Use HiveBoxes.userBox instead. |
| HiveTypeAdapterIdRule | Validates @HiveType(typeId: x) presence and uniqueness. | Missing or duplicate typeId. | Add/adjust typeIds sequentially (0,1,2...). |
| HiveFieldAnnotationRule | Ensures @HiveField(index) exists for persisted fields. | Missing annotation. | Add @HiveField(0) etc. |
| SocketEventsDeclarationRule | SocketEvents constants: camelCase id, snake\_case string. | Non-camel or missing “on/emit”. | Rename and format properly. |
| SocketOnUsageRule | Forbids magic strings in socket.on(). | socket.on('user\_joined'). | Use SocketEvents.onUserJoined. |
| SocketEmitUsageRule | Forbids magic strings in socket.emit(). | socket.emit('user\_left'). | Use SocketEvents.emitUserLeft. |
| MagicNumberDetectionRule | Detects un-named numeric literals. | const x \= 42; in code. | Extract to named const (e.g., const kAnswer \= 42;). |
| MagicStringDetectionRule | Detects hard-coded strings not in const context. | "https://api...". | Extract to a const variable. |
| ScreamingCaseDetectionRule | Flags ALL\_CAPS constants. | const MY\_CONST \= 1;. | Rename to kMyConst. |
| TopLevelKPrefixConstRule | Top-level const must start with k prefix. | const baseUrl \= ...;. | Rename to kBaseUrl. |
| StaticConstInClassRule | Class constants must be static const and no k prefix. | Missing static. | Add static or remove k. |
| ConstantsGroupingRule | Enforces all top-level consts belong in a constants file. | Const in wrong file. | Move to \_constants.dart. |
| EnumValueCamelCaseRule | Enum values must be lowerCamel. | SUNDAY or Sun\_day. | Rename to sunday. |
| EnumDisplayAndColorExtensionRule | Enums must have display/color extensions. | Missing extension(s). | Add extension EnumX and extension EnumColorX. |
| EnumEnhancedPatternRule | Enhanced enums with fields must define constructor and consistent args. | Enum missing constructor. | Add const Enum(this.field) and match args. |
| PrivateFieldNamingRule | Public class fields shouldn’t start \_, private class fields should. | class \_User { String name; }. | Rename to \_name. |
| NonFinalFieldDetectionRule | Non-final instance fields not allowed (except in State/model). | Mutable field found. | Add final. |
| PublicPrivateOrderRule | Public members should appear before private ones. | Public member after \_private. | Reorder members. |
| MethodAccessLevelRule | Non-lifecycle methods should be private. | void helper(). | Rename to \_helper. |
| AsyncReturnTypeRule | Async funcs must return Future\<T\>. | void doWork() async. | Change to Future\<void\>. |
| AsyncSuffixNamingRule | Async funcs must end with Async. | fetchData() async. | Rename to fetchDataAsync(). |
| VoidAsyncDetectionRule | Flags void async functions. | void runAsync() async. | Use Future\<void\>. |
| AsyncErrorHandlingRule | Async funcs must have try/catch or .catchError. | Missing error handling. | Add try/catch. |
| PublicApiDocumentationRule | All public APIs must have Dartdoc (///). | Missing docs. | Add /// documentation. |
| DocumentationQualityRule | Ensures docs are meaningful and formatted properly. | Too short or starts lowercase. | Improve doc comment. |
| TodoFormatRule | Enforces // TODO(username): message YYYY-MM-DD. | Missing assignee/date. | Add TODO(user): ... YYYY-MM-DD. |
| CommentedOutCodeDetectionRule | Detects commented-out code (dead code). | Commented code detected. | Remove or delete commented code. |
| ImportOrderAndGroupingRule | Enforces import order and blank line grouping. | Imports unordered or ungrouped. | Reorder & format imports. |
| RelativeVsAbsoluteImportRule | Enforces absolute imports (package:) in /lib/. | Relative import found. | Replace with package:your\_app/.... |
| ConstConstructorUsageRule | Widget classes should have const constructors. | Missing const keyword. | Add const. |
| TrailingCommaEnforcementRule | Enforces trailing comma in multiline lists/args. | Missing trailing comma. | Add a comma. |
| ResourceDisposalAndDisposeRule | Checks if disposable resources cleaned up in dispose(). | Missing dispose call. | Add controller.dispose(). |
| DeepWidgetNestingAndComplexityRule | Detects deep widget nesting (\>12) or \>40 widgets. | Too many nested widgets. | Refactor into sub-widgets. |
| DisposeMethodPresenceRule | Ensures dispose() exists if resources/lifecycle present. | Missing dispose method. | Add @override void dispose() { ... }. |

**How to Test in Your Project**  
Inside your Main App folder:  
dart run custom\_lint

and you’ll see all rule violations printed with the same format.  
