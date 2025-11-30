import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/button_styles.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/widgets/app_text.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final TextEditingController _helpController = TextEditingController();
  final TextEditingController _issueController = TextEditingController();

  @override
  void dispose() {
    _helpController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    // Send message logic
    if (_helpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe how we can help you')),
      );
      return;
    }

    // TODO: Implement send message API call
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Message sent successfully')));
  }

  void _openWhatsApp() {
    // TODO: Implement WhatsApp integration
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.black, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          text: 'Contact Us',
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),

                SizedBox(height: 16.h),

                // How can we help you
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: AppText(
                    text: 'How can we help you',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.lightGrey,
                  ),
                ),

                SizedBox(height: 8.h),

                // Help Text Field
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildTextField(
                    controller: _helpController,
                    maxLines: 2,
                  ),
                ),

                SizedBox(height: 24.h),

                // Describe your issue (Optional)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: AppText(
                    text: 'Describe your issue (Optional)',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.lightGrey,
                  ),
                ),

                SizedBox(height: 8.h),

                // Issue Text Field
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildTextField(
                    controller: _issueController,
                    maxLines: 6,
                  ),
                ),

                SizedBox(height: 32.h),

                // Send Message Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendMessage,
                      style: ButtonStyles.lightgreenButton,
                      child: AppText(
                        text: 'Send message',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.loaderGreen,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 120.h),
              ],
            ),
          ),

          // WhatsApp Floating Button
          Positioned(
            bottom: 40.h,
            right: 20.w,
            child: GestureDetector(
              onTap: _openWhatsApp,
              child: Container(
                width: 56.w,
                height: 56.h,
                decoration: const BoxDecoration(
                  color: AppColors.lightGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset("assets/svgs/profile/whatsapp.png"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.5)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14.sp,
          color: AppColors.darkGrey,
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
