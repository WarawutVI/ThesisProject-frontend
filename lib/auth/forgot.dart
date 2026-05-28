import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/widgets/language_toggle_button.dart';
import 'package:get/get.dart';

class Forgot extends StatefulWidget {
  const Forgot({super.key});

  @override
  State<Forgot> createState() => _ForgotState();
}

class _ForgotState extends State<Forgot> {
  final TextEditingController email = TextEditingController();
  bool isEnglish = true;

  String t(String en, String th) => isEnglish ? en : th;

  Future<void> reset() async {
    if (email.text.trim().isEmpty) {
      Get.snackbar(
        t("Notice", "แจ้งเตือน"),
        t("Please enter your email first", "กรุณากรอกอีเมลก่อนครับ"),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.amber,
        colorText: Colors.black,
      );
      return;
    }

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email.text.trim());

      Get.back();

      Get.defaultDialog(
        title: t("Link Sent", "ส่งลิงก์สำเร็จ"),
        middleText: t(
          "Please check your email inbox",
          "กรุณาตรวจสอบกล่องจดหมายในอีเมลของคุณ",
        ),
        textConfirm: t("OK", "ตกลง"),
        confirmTextColor: Colors.white,
        buttonColor: const Color(0xFF1A6B45),
        onConfirm: () {
          Get.back();
          Get.back();
        },
      );
    } on FirebaseAuthException catch (e) {
      Get.back();

      String message = t("An error occurred, please try again", "เกิดข้อผิดพลาด กรุณาลองใหม่");
      if (e.code == 'user-not-found') {
        message = t("Email not found in the system", "ไม่พบอีเมลนี้ในระบบ");
      }

      Get.snackbar(
        t("Failed", "ล้มเหลว"),
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A7A50),
      body: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: const Icon(Icons.arrow_back_ios,
                            color: Colors.white70, size: 20),
                      ),
                      LanguageToggleButton(
                        isEnglish: isEnglish,
                        onChanged: (v) => setState(() => isEnglish = v),
                        pillStyle: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t('Forgot\nPassword? 🔑', 'ลืม\nรหัสผ่าน? 🔑'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      "Enter your email and we'll send a reset link",
                      'กรอกอีเมลและเราจะส่งลิงก์รีเซ็ตให้คุณ',
                    ),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('RESET PASSWORD', 'รีเซ็ตรหัสผ่าน'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: t('Email address', 'อีเมลของคุณ'),
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFEBF5EF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: reset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A6B45),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          t('Send Reset Link', 'ส่งลิงก์รีเซ็ต'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: RichText(
                          text: TextSpan(
                            text: t('Remember your password? ', 'จำรหัสผ่านได้แล้ว? '),
                            style: const TextStyle(color: Colors.black54),
                            children: [
                              TextSpan(
                                text: t('Log in', 'เข้าสู่ระบบ'),
                                style: const TextStyle(
                                  color: Color(0xFF1A6B45),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
