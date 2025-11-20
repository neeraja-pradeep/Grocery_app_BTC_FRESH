  
**Flutter Mobile Responsiveness using flutter\_screenutil**

**Why Do We Need flutter\_screenutil?**

In mobile app development:

* Your designs are usually based on a fixed screen size (e.g., 390×835 in Figma).

* But real devices vary in screen width, height, pixel density (e.g., small phones, tablets …).

* If you use hardcoded pixel values, your layout may:

  * Overflow on small screens 

  * Leave too much white space on large screens 

  * Look disproportionate 

**flutter\_screenutil** solves this by scaling every dimension proportionally to the device's actual screen size.

**How to implement?**

1. **Install the Library**  
     In your pubspec.yaml file:  
   dependencies:  
     		flutter\_screenutil: ^5.5.4  
   

Then run: flutter pub get

2. **Set the Figma Base Size:**  
     Check your Figma artboard size.  
    	For example,  it's:

   width: 390px  
   height: 835px

     This will be your designSize.  
3.  **Initialize ScreenUtil in main.dart**

       This wraps your app and tells flutter\_screenutil how to calculate scaling ratios:

import 'package:flutter/material.dart';

import 'package:flutter\_screenutil/flutter\_screenutil.dart';

import 'slider\_screen.dart'; // your actual entry screen

void main() {

  runApp(

    ScreenUtilInit(

      designSize: const Size(390, 835), // your Figma base size

      minTextAdapt: true,               // auto-scale text

      splitScreenMode: true,            // support split screen

      builder: (context, child) {

        return MaterialApp(

          debugShowCheckedModeBanner: false,

          home: child,

        );

      },

      child: const SliderScreen(),

    ),

  );

}

4. Use .sw, .sh, .sp, .r in Your UI:  
   Now replace all hardcoded pixel values (like width: 300, padding: 16, fontSize: 14\) with:

| Purpose | Instead of | Use |
| :---- | ----- | ----- |
| Width | width: 300 | width: 300.w |
| Height | height: 200 | height: 200.h |
| Font size | fontSize: 16 | fontSize: 16.sp |
| Border radius | Radius.circular(25) | Radius.circular(25.r) |
| Padding, margin | EdgeInsets.all(20) | EdgeInsets.all(20.w) or .h |
| Screen size (100%) | MediaQuery.of(context).size.width | 1.sw |
| Half screen height | — | [0.5.sh](http://0.5.sh) |

   

   **FlutterScreen Code for reference:**

   import 'package:flutter/material.dart';

   import 'package:flutter\_screenutil/flutter\_screenutil.dart';

   

   class SliderScreen extends StatelessWidget {

     const SliderScreen({super.key});

   

     @override

     Widget build(BuildContext context) {

       return Scaffold(

         backgroundColor: Colors.black,

         body: Stack(

           children: \[

             // Image: top 612px \-\> 612/835 \= 0.7335

             Positioned(

               top: 0,

               left: 0,

               right: 0,

               height: 0.7335.sh,

               child: Image.asset('assets/images/slider\_image.png', fit: BoxFit.cover),

             ),

   

             // Grey gradient: 305px from bottom

             Positioned(

               bottom: 0,

               left: 0,

               right: 0,

               height: 0.365.sh, // 305/835

               child: Container(

                 decoration: BoxDecoration(

                   gradient: LinearGradient(

                     begin: Alignment.bottomCenter,

                     end: Alignment.topCenter,

                     colors: \[

                       Colors.grey.withOpacity(0.6),

                       Colors.grey.withOpacity(0.0),

                     \],

                   ),

                 ),

               ),

             ),

   

             // Headline Text at 539px from top

             Positioned(

               top: 0.6455.sh, // 539/835

               left: 0.066.sw, // 26/390

               right: 0.066.sw,

               child: Text(

                 "Find Barbers And\\nSalons Easily in Your\\nHands",

                 textAlign: TextAlign.center,

                 style: TextStyle(

                   fontSize: 32.sp,

                   fontWeight: FontWeight.bold,

                   color: Color(0xFFFFB74D),

                 ),

               ),

             ),

   

             // Button: 65px from bottom, 315px wide

             Positioned(

               bottom: 0.077.sh, // 65/835

               left: 0.0948.sw, // 37/390

               right: 0.0948.sw,

               child: SizedBox(

                 width: 0.807.sw, // 315/390

                 height: 0.0419.sh, // 35/835

                 child: ElevatedButton(

                   onPressed: () {},

                   style: ElevatedButton.styleFrom(

                     backgroundColor: Color(0xFFFFB74D),

                     shape: RoundedRectangleBorder(

                       borderRadius: BorderRadius.circular(50.r),

                     ),

                   ),

                   child: Text(

                     'NEXT',

                     style: TextStyle(

                       fontSize: 16.sp,

                       fontWeight: FontWeight.bold,

                       color: Colors.black,

                     ),

                   ),

                 ),

               ),

             ),

           \],

         ),

       );

     }

   }

   

   Note: Never use const with .sp, .w, .h, .r, const makes the widget unscalable

   

   