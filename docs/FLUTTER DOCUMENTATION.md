FLUTTER DOCUMENTATION

Flutter is a framework for building mobile applications. You write code once and it runs on both iOS and Android — the same codebase, one deployment.
The language you write in is called Dart.
Here is how a Flutter app is fundamentally different from a website:In a website, you have HTML for structure, CSS for styling, and JavaScript for logic — three separate concerns in three different places.
In Flutter, there is no HTML and no CSS. Every single thing you see on screen — a button, a text label, a list, a card — is a Dart object. It is called a Widget. Structure, styling, and layout are all written together inside that widget in Dart.

Why Layers Exist — The Big Picture
Before we look at any code, you need to understand WHY the project is structured the way it is. Once you understand the why, every folder and file name will make sense on its own.
When an app is small, it's tempting to put everything in one place — the API call, the business logic, the UI update — all inside one file. That works for a prototype. But when the app grows, that approach creates serious problems.
A bug in the API call breaks the UI. A change in how data is displayed forces you to rewrite the data fetching logic. Nothing is reusable. Testing becomes nearly impossible.

To solve this, this project separates responsibilities into four layers. Each layer has exactly one job. No layer does another layer's job.

DOMAIN LAYER - declared
INFRASTRUCTURE LAYER- defined
APPLICATION LAYER- called
PRESENTATION LAYER- displayed


DOMAIN LAYER:

features/auth/domain/
   ├── entities/
   └── repositories/

The domain layer is the foundation of every feature. It answers two questions and only two questions:
One — what does the data look like?
Two — what operations are available?



The domain layer has two things inside it.

First — Entities. An entity is a plain Dart class that describes what a piece of data looks like. A `User` entity has an id, a name, an email. That's it. No methods that fetch data. No UI logic. Just the shape of the data."

class User {
 final String id;
 final String name;
 final String email;

 const User({
   required this.id,
   required this.name,
   required this.email,
 });
}
```
Second — Repositories in the Domain layer. This is the first place repositories appear, and it is important to understand exactly what they are here."

A domain repository is NOT code that fetches data. It is a declaration — a list of method signatures that says 'these operations exist on this feature'. It uses the Dart keyword `abstract`, which means: this class cannot be run directly. It is a promise that someone else will provide the real implementation."

abstract class AuthRepository {
 Future<User> login(String email, String password);
 Future<void> logout();
 Future<User> getProfile();
}

Infrastructure Layer

features/auth/
└── infrastructure/
   ├── data_sources/
   │   ├── remote/     ← API calls via Dio
   │   └── local/      ← Hive reads and writes
   └── repositories/   ← implements the domain contract

The infrastructure layer is built directly on top of the domain layer. It is the only layer in the entire project that is allowed to talk to the outside world — the server API and the device's local database.
It has three parts: 1. `remote/` 2. `local/`  and 3. `repositories/`

 `remote/` for API calls This is one class per feature, named with an `Api` suffix — `AuthApi`, It is a thin layer. Its only job is to make the HTTP call, receive the raw response, and convert it into a domain entity. No business logic. No caching decisions. Just the network call.

 
// infrastructure/data_sources/remote/auth_api.dart

 class AuthApi {
   final Dio _dio;

   AuthApi(this._dio);

   Future<User> login(String email, String password) async {
     final response = await _dio.post(
       '/auth/login',
       data: {'email': email, 'password': password},
     );
     return User.fromJson(response.data);  // converts raw JSON to a domain entity
   }
 }
 ```

—-------------------
 `local/` for Hive database operations, This is the only place in the entire project where Hive is read from or written to. Not in UI. Not in providers. Only here

Hive is the local database on the device. When the repository needs data, it does not immediately call the network. It checks three places in order, fastest to slowest. This is the cache hierarchy.
Memory Cache-Data held in RAM while the app is running-Cleared when the app closes or restarts.
           |
Hive Cache - Data written to the device's file storage- Survives app restarts. Works with no internet.
           |
Network- HTTP call via Dio to the server API-Slowest. Requires internet- On success: result saved into L2 and L1.

HIVE implementation scenarios
Scenario 1 — First time opening the app
Nothing cached anywhere. Memory: miss. Hive: miss. App shows a skeleton loading screen while making the API call. Response arrives, data is shown, saved to Hive and memory.


Scenario 2 — Opening the app again
Memory: miss — app restarted, RAM cleared. Hive: hit. Cached data loads into memory and is shown immediately in about 50 milliseconds — no spinner at all. In the background, the app quietly checks the API for newer data. If the server has updates, UI transitions smoothly. If not, nothing changes
Scenario 3 — No internet.
Memory: miss. Hive: hit. App shows cached data and puts a small offline indicator on screen. The network call fails silently — no crash, no error screen, just a banner that states this is old data or no internet connection. When internet returns, the app retries once automatically.
Scenario 4 — Cache is older than 24 hours.
Hive has data but it is stale. App shows it with an amber warning banner: 'Data from 1 day ago — tap to refresh'. Background retry starts with increasing delays — 0s, 2s, 4s, 8s, up to 4 attempts. If all fail, banner stays. User can tap it to force an immediate retry


how a Hive model is defined. Every class you want to store in Hive needs two annotations.
```dart
@HiveType(typeId: 2)          // unique integer ID for this model across the whole app
class WorkoutModel {

 @HiveField(0)               // index Hive uses to serialize this field
 final String name;

 @HiveField(1)               // each field gets its own index, starting from 0
 final int duration;
}

`typeId` must be unique across every Hive model in the entire project — no two models can share the same number. `HiveField` index is how Hive identifies the field when reading and writing. If you change the index number after data has been saved to a device, that data will be read incorrectly.
—------------
 
 And `repositories/` — it contains the real code that does the work.
which is the second place you see a repositories folder.


The domain repository-— it lists what operations must exist for a feature. No code. No Hive. No API calls. Just the list.
abstract class AuthRepository {
 Future<User> login(String email, String password);
 Future<void> logout();
 Future<User> getProfile();
}

This file has no code inside the methods.
No curly braces. No logic. Just the list of what must exist.
The infrastructure repository
class AuthRepositoryImpl implements AuthRepository {

 Future<User> login(String email, String password) async {
   // Step 1: check if we already have this data in Hive
   final cached = _local.getUser();
   if (cached != null) return cached;

   // Step 2: no cache — call the API
   final user = await _remote.login(email, password);

   // Step 3: save the result to Hive for next time
   _local.saveUser(user);
   return user;
 }

 Future<void> logout() async { ... }

 Future<User> getProfile() async { ... }
}

This file has real code. Real Hive reads. Real API calls.

—------------------------------
Application Layer
features/auth/
└── application/
   ├── states/      ← shape of the feature's state at any moment
   ├── providers/   ← Riverpod lives here
   └── usecases/    ← optional: complex multi-step operations

The Application layer sits above Infrastructure and below Presentation. It is the brain of each feature.
This layer is responsible for two things only.
One — holding the state of the feature at any given moment.
Two — running business logic when something happens.

It knows WHAT to do. It does not know HOW data is physically fetched. That is Infrastructure's job. The Application layer calls through the domain contract and Infrastructure handles the rest.

This is where Riverpod lives. Riverpod is the state management system for the entire project. Any data that needs to be shared across screens, or that needs to survive widget rebuilds, lives in a Riverpod Provider.
Before we look at Riverpod, understand what 'state' means here.
State is the complete snapshot of a feature at a given moment. For the login feature: is a request in progress? Did it succeed? Did it fail with an error message? The UI reads this snapshot and draws itself based on it.


Riverpod has four Provider types. Each is for a specific situation.

Provider                   Static values that never change — config, utils
StateProvider              A single value that changes — a boolean, a counter
FutureProvider             Reading async data (read-only, no mutations)
StateNotifierProvider      Any real feature — state with multiple actions


Part 1 — The State class
This is a plain Dart class that holds the current situation of the login feature. ``dart
// application/states/auth_state.dart

class LoginState {
 final bool isLoading;        // is a request in progress?
 final String? errorMessage;  // any error to show? null = no error
 final bool isSuccess;        // did login succeed?

 const LoginState({
   this.isLoading = false,     // default: nothing happening
   this.errorMessage,
   this.isSuccess = false,
 });
}
```
All three fields are `final` — meaning once this object is created, you cannot change those values. So how does the scoreboard ever update?
You do not change the existing object. You create a brand new one with only the field that changed, and copy everything else from the old object. The `copyWith` method does this.
```dart
// I want to show a loading spinner. Only isLoading changes.
// Everything else stays the same.

state = state.copyWith(isLoading: true);

// Before:  isLoading=false, errorMessage=null, isSuccess=false
// After:   isLoading=true,  errorMessage=null, isSuccess=false
//                    ↑ changed                 ↑ copied from old
```


art 2 — The Controller
The controller is the only place in the entire feature allowed to create new State objects. It holds the domain repository and calls it when an action is triggered.
```dart
// application/providers/login_controller.dart

class LoginController extends StateNotifier<LoginState> {

 final AuthRepository _repository;  // the domain contract — not the implementation

 LoginController(this._repository) : super(const LoginState());
 //                                         ↑ start with the default state

 Future<void> login(String email, String password) async {

   // User tapped login — show the spinner
   state = state.copyWith(isLoading: true, errorMessage: null);

   try {
     await _repository.login(email, password);
     // calls down to Infrastructure — controller never sees Hive or Dio

     // It worked — update the scoreboard
     state = state.copyWith(isSuccess: true, isLoading: false);

   } catch (e) {
     // Something failed — show the error
     state = state.copyWith(errorMessage: e.toString(), isLoading: false);
   }
 }
}
```

Part 3 — The Provider registration
This registers the controller with Riverpod so any widget in the app can find it. It is just wiring — nothing else.
```dart
final loginControllerProvider =
   StateNotifierProvider<LoginController, LoginState>((ref) {
 return LoginController(ref.read(authRepositoryProvider));
 //                     ↑ Riverpod creates the controller
 //                       and injects AuthRepositoryImpl automatically
});
```
Read it as: 'There is a provider named `loginControllerProvider`. When any widget asks for it, create a `LoginController` and give it the auth repository.' That is the entire purpose of this block.


Now — how does the Presentation layer actually read this state and trigger actions?

```dart
// In any ConsumerWidget:

final state = ref.watch(loginControllerProvider);
// ref.watch subscribes to the provider.
// Every time state changes, this widget rebuilds automatically.
// Use ONLY inside the build() method.

ref.read(loginControllerProvider.notifier).login(email, password);
// ref.read fires once without subscribing.
// Use ONLY inside callbacks — onPressed, onChanged, etc.
// Never use ref.read in build() for reactive state.
```


Presentation Layer

features/auth/
└── presentation/
   ├── screen/      ← full pages
   └── components/  ← reusable UI pieces within this feature


The Presentation layer is the top layer — what the user sees and touches. Two strict rules:
Rule one — only UI code lives here. No business logic. No API calls. No Hive reads.
Rule two — it reads state from the Application layer via Riverpod and calls methods on the Application layer. It never reaches directly into Infrastructure or Domain.

Before we look at widget types, understand what a widget actually is on screen.

Your phone screen is a blank canvas. Every single thing painted on that canvas is a widget — the text, the button, the image, the space between two elements. Widgets are placed inside other widgets to build the full layout. Like boxes inside boxes.



There are three types of widget. Before writing any widget, ask this question:
Does this widget need to read from Riverpod?
       │
       ├── YES → ConsumerWidget
       │         screens, any widget showing live app data
       │
       └── NO
           │
           Does it manage its own small visual state?
           │
           ├── YES → StatefulWidget
           │         password show/hide, dropdown open/close,
           │         tab selection — purely how it looks
           │
           └── NO  → StatelessWidget
                      a card showing a name, a header,
                      a reusable button — just receives and draws


StatelessWidget — a printed photograph. You give it data, it shows it. It has no memory. It cannot change itself. Give it the same inputs every time and it always produces the same output.

```dart
// This widget receives a name and avatar URL.
// It draws them. That is all it does.

class UserCard extends StatelessWidget {
 final String name;         // data passed in from outside
 final String avatarUrl;

 const UserCard({super.key, required this.name, required this.avatarUrl});

 @override
 Widget build(BuildContext context) {
   // Flutter calls build() to ask: what should appear on screen?
   return Column(
     children: [
       Image.network(avatarUrl),
       Text(name),
     ],
   );
 }
}
```
StatefulWidget — a light switch. The switch itself knows whether it is on or off. That is local state — it belongs to the switch, not to anyone else. When you flip it, only that switch updates.

Use StatefulWidget only for state that is purely about how the widget looks. Actual data always goes in Riverpod.
```dart
// This widget tracks one thing only: is the password currently visible?
// That belongs to this widget alone — it is a visual concern, not a data concern.

class PasswordField extends StatefulWidget {
 @override
 State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
 bool _isVisible = false;   // local state — starts hidden

 @override
 Widget build(BuildContext context) {
   return TextField(
     obscureText: !_isVisible,   // hides or shows the text
     decoration: InputDecoration(
       suffixIcon: IconButton(
         icon: Icon(
           _isVisible ? Icons.visibility_off : Icons.visibility,
         ),
         onPressed: () {
           setState(() {
             _isVisible = !_isVisible;
             // setState tells Flutter:
             // "local state changed — rebuild just this widget"
           });
         },
       ),
     ),
   );
 }
}
```

ConsumerWidget — a TV connected to a cable box. The cable box is Riverpod. The TV does not decide what to show — it shows whatever the cable box is broadcasting. When the broadcast changes, the TV updates automatically.
Your screens will mostly be ConsumerWidgets because screens need to read from the Application layer and react when state changes.

``dart
class LoginScreen extends ConsumerWidget {
 @override
 Widget build(BuildContext context, WidgetRef ref) {
   // ref is the cable connection to Riverpod

   // ref.watch subscribes — every time LoginState changes,
   // Flutter calls build() again and the screen redraws
   final state = ref.watch(loginControllerProvider);

   return Scaffold(
     appBar: AppBar(title: Text('Login')),
     body: Column(
       children: [
         TextField(controller: emailController),
         TextField(controller: passwordController, obscureText: true),

         ElevatedButton(
           onPressed: () {
             // ref.read fires once — does not subscribe, does not rebuild
             // use inside callbacks only
             ref.read(loginControllerProvider.notifier)
                .login(emailController.text, passwordController.text);
           },
           child: state.isLoading
               ? CircularProgressIndicator()  // state says loading → show spinner
               : Text('Login'),              // state says idle → show button text
         ),

         // this Text only appears when errorMessage is not null
         if (state.errorMessage != null)
           Text(state.errorMessage!, style: TextStyle(color: Colors.red)),
       ],
     ),
   );
 }
}
```


Responsive UI with ScreenUti
Mobile devices come in hundreds of screen sizes. A layout with hardcoded pixel values that looks correct on one device will overflow on a smaller phone and leave excess whitespace on a larger one.


