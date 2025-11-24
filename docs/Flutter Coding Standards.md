# **Flutter Coding Standards & Guidelines (Project-Wide)**

## **1\. Project Architecture**

### **1.1 Architecture Pattern**

Use **Feature-First folder structure**:

 [`Use this document to get the detailed structure`](https://docs.google.com/spreadsheets/d/1jpdUvn0JjxxaJVbYWeoFKr8m-Pb8onaXvnuOIfOtgsk/edit?gid=881682575#gid=881682575)

* Separate:

  * **Data layer** → API calls, Hive, repositories

  * **Domain layer** → business logic, use cases (optional if project needs)

  * **Presentation layer** → UI, controllers (Riverpod providers)

### **1.2 Naming Conventions**

* Files: `snake_case`

* Classes: `PascalCase`

* Variables & methods: `camelCase`

* Constants: `CONSTANT_CASE`

* Provider names must end with `Provider`.

  We provide a detailed guide for LINT ANALYSIS, please implement this outside your project root folder:  
  [Implementation guide Lint Analysis](https://docs.google.com/document/d/1qmpuZNyOp5_lPmUeS8zG1bmsA_l_A9hE0MjwR8wZ270/edit?tab=t.0)

---

# **2\. State Management (Riverpod)**

### **2.1 Provider Types**

* Use `StateNotifierProvider` for feature-level business logic.

* Use `FutureProvider` for API-driven async reads.

* Use `Provider` only for static configurations/utilities.

* Use `StateProvider` ONLY for basic UI states.

### **2.2 Best Practices**

* Keep providers in a dedicated `/providers` folder inside each feature.

* Never mutate state directly; always use immutable state classes.

* Keep UI widgets **pure**—UI should read state and call the controller, nothing else.

* Avoid placing heavy logic directly inside UI.

### **2.3 Good Example**

`final loginControllerProvider =`  
    `StateNotifierProvider<LoginController, LoginState>((ref) {`  
  `return LoginController(ref.read);`  
`});`

---

# **3\. Caching (Hive)**

### **3.1 Box Naming Rules**

* Use **clear**, **feature-based box names**:

  * `auth`

  * `workouts`

  * `vitals_cache`

  * `settings`

* Never use generic names like `box1` or `myBox`.

### **3.2 Model \+ Adapter Rules**

* Every cache model must:

  * Use `@HiveType` and unique `typeId`.

  * Have a dedicated file in `data/models`.

Example:

`@HiveType(typeId: 2)`  
`class WorkoutModel {`  
  `@HiveField(0)`  
  `final String name;`

  `@HiveField(1)`  
  `final int duration;`  
`}`

### **3.3 Usage Best Practices**

* Cache only final API results, not partial/unsure data.

* Keep Hive read/write logic only inside repositories, never inside UI or providers.

* Always provide fallback UI when cached data is empty.

---

# **4\. UI/UX & Layout (ScreenUtil)**

### **4.1 Initialization**

Call `ScreenUtil.init` in `main.dart` inside `builder` or app entry.

### **4.2 DOs**

* Use:

  * `.h` for heights

  * `.w` for widths

  * `.sp` for fonts

  * `.r` for border radius, padding

Always ensure:

 `textScaleFactor: 1.0,`

* 

### **4.3 DON'Ts**

* Do not use hardcoded pixel values.

* Do not mix `% based layout` and ScreenUtil unless necessary.

* Do not use `Expanded` inside `SingleChildScrollView`.

  [Detailed Implementation guide for Flutter Screen util](https://docs.google.com/document/d/1ATWtqfvyqGOOi6EYtvKOJpthmr0cnM7S-qEi_rxQCoo/edit?tab=t.0)

---

# **5\. Error Handling & Logging**

### **5.1 Error Handling**

* Always handle:

  * API errors

  * Hive exceptions

  * JSON parsing failures

### **5.2 Standard Error Model**

Every feature should have a reusable `Failure` or `AppError` class.

---

# **6\. API Integration**

### **6.1 API Service Rules**

* Use a single `ApiService` class for all network calls.

* Every feature must have its own repository.

* Do not call API directly inside controllers or providers.

### **6.2 Token Handling**

* Store access/refresh tokens in Hive only.

* Use interceptors or retry logic for token refresh.

* On 401:

  * Refresh token

  * Retry once

  * If fails → logout

---

# **7\. Code Style & Formatting**

### **7.1 General Standards**

* Use `dart fix` and `dart format` before every commit.

* Maintain 80–100 line length where possible.

* Avoid deeply nested widgets; extract into small reusable widgets.

### **7.2 Widget Building**

* StatelessWidget \> StatefulWidget (prefer state in providers)

* Extract widgets when:

  * build() exceeds 100–150 lines

  * widget repeats in multiple places

  * logic becomes unclear

### **7.3 Null Safety Standards**

* Never use `!` unless absolutely required.

* Prefer:

  * `??`

  * named parameters with required keyword

  * safe navigation (`?.`)

---

# **8\. Performance Best Practices**

* Memoize heavy widgets using `const` and `ConsumerWidget`.

* Use `select` to read only needed parts of provider state.

Avoid expensive rebuilds:

 `ref.watch(provider.select((state) => state.subField));`

* Dispose controllers manually when required.

* Use pagination & lazy loading for long lists.

---

# **9\. Security Guidelines**

* Never store passwords or sensitive data in Hive.

* Hide API keys using remote config or backend environment variables.

* Validate all inputs on both client \+ server side.

* Use HTTPS everywhere.

---

# **10\. Git & Commit Practices**

###  **Branching**

* `main` → production

* `dev` → staging

* feature branches → `feature/<feature_name>`

---

**11\. Pre-Commit Hooks**

[Detailed implementation guide (Strictly implement this in your project)](https://docs.google.com/document/d/16YrLXdCqIlWWBdKVcWYWf2-J6fMXkovnGlH9k6AdK3U/edit?tab=t.0)

