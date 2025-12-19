import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_snackbar.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  // WhatsApp number for contact
  static const String whatsAppNumber = '+919876543210';

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final subject = _subjectController.text.trim();

    if (subject.isEmpty) {
      AppSnackbar.info(context, 'Please enter how we can help you');
      return;
    }

    setState(() => _isLoading = true);

    // Simulate sending message
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    if (mounted) {
      AppSnackbar.success(context, 'Message sent successfully!');
      _subjectController.clear();
      _descriptionController.clear();
    }
  }

  void _openWhatsApp() {
    // Show WhatsApp number with option to copy
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/svgs/profile/whatsapp.png',
                width: 32.w,
                height: 32.w,
              ),
            ),
            SizedBox(height: 16.h),
            AppText(
              text: 'Contact us on WhatsApp',
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
            SizedBox(height: 8.h),
            AppText(
              text: whatsAppNumber,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.grey,
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: whatsAppNumber));
                  Navigator.pop(context);
                  AppSnackbar.success(
                    context,
                    'Phone number copied to clipboard',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
                child: AppText(
                  text: 'Copy Number',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
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
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject field label
                  AppText(
                    text: 'How can we help you',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.grey,
                  ),
                  SizedBox(height: 8.h),

                  // Subject text field
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.green, width: 1),
                    ),
                    child: TextField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        hintText: '',
                        hintStyle: TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: 14.sp,
                        ),
                      ),
                      style: TextStyle(fontSize: 14.sp, color: AppColors.black),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Description field label
                  AppText(
                    text: 'Describe your issue (Optional)',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.grey,
                  ),
                  SizedBox(height: 8.h),

                  // Description text area
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.green, width: 1),
                    ),
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        hintText: '',
                        hintStyle: TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: 14.sp,
                        ),
                      ),
                      style: TextStyle(fontSize: 14.sp, color: AppColors.black),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Send message button
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : AppText(
                              text: 'Send message',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // WhatsApp floating button
            Positioned(
              bottom: 30.h,
              right: 20.w,
              child: GestureDetector(
                onTap: _openWhatsApp,
                child: Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/svgs/profile/whatsapp.png',
                      width: 42.w,
                      height: 42.w,
                      errorBuilder: (_, e, s) =>
                          Icon(Icons.chat, color: Colors.white, size: 28.sp),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
