import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/widgets/language_toggle_button.dart';
import 'package:frontend/auth/forgot.dart';
import 'package:frontend/auth/signup.dart';
import 'package:frontend/wrapper.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  bool isEnglish = true;
  bool _passwordVisible = false;

  String t(String en, String th) => isEnglish ? en : th;

  loginwithform() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      Get.snackbar(
        t("Notice", "แจ้งเตือน"),
        t("Please fill in all fields", "กรุณากรอกข้อมูลให้ครบถ้วน"),
        backgroundColor: Colors.amber,
      );
      return;
    }

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );

      Get.back();
    } on FirebaseAuthException catch (e) {
      Get.back();

      String message = t("An error occurred", "เกิดข้อผิดพลาด");
      if (e.code == 'user-not-found') {
        message = t("Email not found", "ไม่พบอีเมลนี้ในระบบ");
      } else if (e.code == 'wrong-password') {
        message = t("Incorrect password", "รหัสผ่านไม่ถูกต้อง");
      } else if (e.code == 'invalid-email') {
        message = t("Invalid email format", "รูปแบบอีเมลไม่ถูกต้อง");
      }

      Get.snackbar(
        t("Login Failed", "เข้าสู่ระบบไม่สำเร็จ"),
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  loginwithgoogle() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId:
            '383298804056-3v7k9oefmo2bbu297s5b8vrb5looiqll.apps.googleusercontent.com',
      );
      
      debugPrint('Starting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      debugPrint('googleUser returned: ${googleUser?.email ?? "null"}');

      if (googleUser == null) {
        Get.back();
        debugPrint('Google Sign-In cancelled by user or failed silently.');
        Get.snackbar(
          t("Cancelled", "ยกเลิก"),
          t("Google sign-in was cancelled or failed",
              "การเข้าสู่ระบบด้วย Google ถูกยกเลิกหรือล้มเหลว"),
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      debugPrint(
          'idToken null? ${googleAuth.idToken == null} | accessToken null? ${googleAuth.accessToken == null}');

      if (googleAuth.idToken == null) {
        Get.back();
        Get.snackbar(
          t("Error", "เกิดข้อผิดพลาด"),
          t("Missing ID token from Google. Check serverClientId / SHA-1.",
              "ไม่ได้รับ ID token จาก Google กรุณาตรวจสอบ serverClientId / SHA-1"),
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await userCredential.user?.delete();
        await googleSignIn.signOut();

        Get.back();
        Get.snackbar(
          t("Account not found", "ไม่พบไอดีในระบบ"),
          t("Please sign up first", "กรุณาไปที่หน้า Signup เพื่อสมัครสมาชิกก่อนใช้งาน"),
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        Get.to(() => const Signup());
        return;
      }

      Get.back();
      Get.offAll(() => const Wrapper());
    } on Exception catch (e) {
      Get.back();
      debugPrint("Detailed Google Sign-In Error: $e");
      Get.snackbar(
        t("Login Failed", "เข้าสู่ระบบไม่สำเร็จ"),
        t("An error occurred: $e", "เกิดข้อผิดพลาด: $e"),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      debugPrint("Unknown Error: $e");
      Get.snackbar(
        t("Login Failed", "เข้าสู่ระบบไม่สำเร็จ"),
        "Unknown error occurred",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType:
          isPassword ? TextInputType.text : TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFEBF5EF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _googleLogo() {
    return const SizedBox(
      width: 22,
      height: 22,
      child: Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
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
                      Text(
                        t('login', 'เข้าสู่ระบบ'),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
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
                    t('Welcome\nback! 👋', 'ยินดี\nต้อนรับ! 👋'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t("Let's Practice Thai Vowels", 'มาฝึกสระภาษาไทยกันเถอะ'),
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
                      t('SIGN IN', 'เข้าสู่ระบบ'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: email,
                      hint: t('Email address', 'อีเมล'),
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: password,
                      hint: t('Password', 'รหัสผ่าน'),
                      icon: Icons.lock_outline,
                      isPassword: true,
                      isVisible: _passwordVisible,
                      onToggleVisibility: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Get.to(() => Forgot()),
                        child: Text(
                          t('forgot  password ?', 'ลืมรหัสผ่าน ?'),
                          style: const TextStyle(
                            color: Color(0xFF1A6B45),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: loginwithform,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A6B45),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          t('Log in', 'เข้าสู่ระบบ'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        t('or continue with', 'หรือดำเนินการต่อด้วย'),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: loginwithgoogle,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _googleLogo(),
                            const SizedBox(width: 10),
                            const Text(
                              'Google',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: () => Get.to(() => const Signup()),
                        child: RichText(
                          text: TextSpan(
                            text: t("Don't have an account? ", 'ยังไม่มีบัญชี? '),
                            style: const TextStyle(color: Colors.black54),
                            children: [
                              TextSpan(
                                text: t('Sign up', 'สมัครสมาชิก'),
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
