// // features/home/presentation/components/location_chip.dart

// // ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors

// import 'package:flutter/material.dart';

// import 'profile_icon_button.dart';

// class LocationChip extends StatelessWidget {
//   // New properties for dynamic location display
//   final String city;
//   final String addressLine1;
//   final String addressLine2;

//   final VoidCallback onLocationTap;
//   final VoidCallback onProfileTap;

//   const LocationChip({
//     super.key,
//     required this.city,
//     required this.addressLine1,
//     required this.addressLine2,
//     required this.onLocationTap,
//     required this.onProfileTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // Color matching the light green strip in the image: #B2D372 or similar light shade
//     const Color lightGreen = Color(0xFFC7E2A6);
//     const Color darkText = Color(0xFF374151); // Darker text color for contrast

//     return Container(
//       // Use the lighter green color for the location strip background
//       color: lightGreen,
//       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           // Location Icon
//           Icon(Icons.location_on, color: darkText, size: 24),
//           SizedBox(width: 8),

//           // Location Text Details (Overflow Fix Applied Here)
//           Expanded(
//             child: GestureDetector(
//               onTap: onLocationTap,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // City and Address Line 1 (Overflowing line in original image)
//                   Row(
//                     children: [
//                       // Text is now composed of multiple fields to better fit the visual
//                       Flexible(
//                         // Use Flexible to control the long text
//                         child: Text(
//                           // Combining city and a part of address
//                           '$city : $addressLine1',
//                           style: TextStyle(
//                             color: darkText,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           maxLines: 1, // Fix overflow
//                           overflow: TextOverflow.ellipsis, // Fix overflow
//                         ),
//                       ),

//                       // Dropdown Icon
//                       Icon(
//                         Icons.keyboard_arrow_down,
//                         color: darkText,
//                         size: 20,
//                       ),
//                     ],
//                   ),

//                   // Address Line 2 (Second line in the image)
//                   Text(
//                     addressLine2,
//                     style: TextStyle(
//                       color: darkText.withValues(alpha: 0.8),
//                       fontSize: 12,
//                     ),
//                     maxLines: 1, // Fix overflow
//                     overflow: TextOverflow.ellipsis, // Fix overflow
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // Profile Icon (Updated to match the image's simple person icon)
//           GestureDetector(
//             onTap: onProfileTap,
//             child: Padding(
//               padding: const EdgeInsets.only(left: 8.0),
//               child: ProfileIconButton(onProfileTap: onProfileTap),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
