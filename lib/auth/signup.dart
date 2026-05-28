import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/widgets/language_toggle_button.dart';
import 'package:frontend/auth/gender.dart';
import 'package:frontend/auth/login.dart';
import 'package:frontend/wrapper.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  TextEditingController username = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();

  bool isEnglish = true;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  String t(String en, String th) => isEnglish ? en : th;

  signup_google() async {
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
      final user = userCredential.user;
      debugPrint("Google Sign-In successful: ${user?.email}");
      
      if (user != null) {
        // If they already have an account, sign them in directly and go to the wrapper/home screen
        if (userCredential.additionalUserInfo?.isNewUser == false) {
          Get.back(); // dismiss loading dialog
          Get.offAll(() => const Wrapper());
          return;
        }

        String displayName = user.displayName?.trim() ?? "";
        if (displayName.isEmpty) {
          displayName = "Unknown User";
        }
        List<String> nameParts = displayName.split(' ');
        String fname = nameParts[0];

        Get.back();
        Get.to(() => GenderPage(
              uid: user.uid,
              username: fname,
              email: user.email ?? "",
              loginProvider: 'google',
              isEnglish: isEnglish,
            ));
        return;
      }

      Get.back();
    } on Exception catch (e) {
      Get.back();
      debugPrint("Detailed Google Sign-In Error: $e");
      Get.snackbar(
        t("Sign up failed", "สมัครสมาชิกไม่สำเร็จ"),
        t("An error occurred: $e", "เกิดข้อผิดพลาด: $e"),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      debugPrint("Unknown Error: $e");
      Get.snackbar(t("Error", "เกิดข้อผิดพลาด"), "Unknown error occurred",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  signup_email() async {
    if (username.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.isEmpty ||
        confirmPassword.text.isEmpty) {
      Get.snackbar(
        t("Notice", "แจ้งเตือน"),
        t("Please fill in all fields", "กรุณากรอกข้อมูลให้ครบถ้วน"),
        backgroundColor: Colors.amber,
      );
      return;
    }

    if (password.text != confirmPassword.text) {
      Get.snackbar(
        t("Notice", "แจ้งเตือน"),
        t("Passwords do not match", "รหัสผ่านไม่ตรงกัน"),
        backgroundColor: Colors.amber,
      );
      return;
    }

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
      final String uid = userCredential.user!.uid;

      Get.back();
      Get.to(() => GenderPage(
            uid: uid,
            username: username.text.trim(),
            email: email.text.trim(),
            loginProvider: 'email',
            isEnglish: isEnglish,
          ));
    } on FirebaseAuthException catch (e) {
      Get.back();
      String message = t("Sign up failed", "สมัครสมาชิกไม่สำเร็จ");
      if (e.code == 'email-already-in-use') {
        message = t("This email is already in use", "อีเมลนี้ถูกใช้งานไปแล้ว");
      } else if (e.code == 'weak-password') {
        message = t("Password must be at least 6 characters",
            "รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร");
      } else if (e.code == 'invalid-email') {
        message = t("Invalid email format", "รูปแบบอีเมลไม่ถูกต้อง");
      }
      Get.snackbar(
        t("Error", "เกิดข้อผิดพลาด"),
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      Get.snackbar(t("Error", "เกิดข้อผิดพลาด"), e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
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
    return SizedBox(
      width: 22,
      height: 22,
      child: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
                text: 'G',
                style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ],
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                     
                      LanguageToggleButton(
                        isEnglish: isEnglish,
                        onChanged: (v) => setState(() => isEnglish = v),
                        pillStyle: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t('Create\naccount ⭐', 'สร้าง\nบัญชี ⭐'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('Start your vowel journey today',
                        'เริ่มต้นการเดินทางของคุณวันนี้'),
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
                      t('YOUR DETAILS', 'รายละเอียดของคุณ'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: username,
                      hint: t('Username', 'ชื่อผู้ใช้'),
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: confirmPassword,
                      hint: t('Confirm Password', 'ยืนยันรหัสผ่าน'),
                      icon: Icons.lock_outline,
                      isPassword: true,
                      isVisible: _confirmPasswordVisible,
                      onToggleVisibility: () => setState(
                          () => _confirmPasswordVisible = !_confirmPasswordVisible),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: signup_email,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A6B45),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          t('Create account', 'สร้างบัญชี'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(t('or', 'หรือ'),
                              style: const TextStyle(color: Colors.grey)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: signup_google,
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
                            Text(
                              t('continue with Google', 'ดำเนินการต่อด้วย Google'),
                              style: const TextStyle(
                                  color: Color(0xFF1A6B45),
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: () => Get.to(() => const Login()),
                        child: RichText(
                          text: TextSpan(
                            text: t('Already have an account? ',
                                'มีบัญชีอยู่แล้ว? '),
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
