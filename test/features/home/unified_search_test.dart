// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:new_app/features/home/presentation/screen/search_screen.dart';

// void main() {
//   group('Unified Search Screen Tests', () {
//     testWidgets('should show history and trending when search is empty', (
//       tester,
//     ) async {
//       await tester.pumpWidget(
//         ProviderScope(
//           child: ScreenUtilInit(
//             designSize: const Size(375, 812),
//             child: MaterialApp(home: const SearchScreen()),
//           ),
//         ),
//       );

//       // Should show recent search and trending sections initially
//       expect(find.text('Recent Search'), findsOneWidget);
//       expect(find.text('Trending Now'), findsOneWidget);
//     });

//     testWidgets('should have real-time search capability', (tester) async {
//       await tester.pumpWidget(
//         ProviderScope(
//           child: ScreenUtilInit(
//             designSize: const Size(375, 812),
//             child: MaterialApp(home: const SearchScreen()),
//           ),
//         ),
//       );

//       // Find the search text field
//       final searchField = find.byType(TextField);
//       expect(searchField, findsOneWidget);

//       // Verify it has onChanged callback (real-time search)
//       final textField = tester.widget<TextField>(searchField);
//       expect(textField.onChanged, isNotNull);
//       expect(textField.onSubmitted, isNotNull);
//     });

//     testWidgets('should show back button for navigation', (tester) async {
//       await tester.pumpWidget(
//         ProviderScope(
//           child: ScreenUtilInit(
//             designSize: const Size(375, 812),
//             child: MaterialApp(home: const SearchScreen()),
//           ),
//         ),
//       );

//       // Should have back button
//       expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
//     });
//   });
// }
