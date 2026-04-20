import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/auth/forgot.dart';
import 'package:frontend/auth/sigup.dart';
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

  loginwithform() async {
    try {
      // แสดง Loading ระหว่างรอ
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );

      Get.back(); // ปิด Loading เมื่อสำเร็จ
    } on FirebaseAuthException catch (e) {
      Get.back(); // ปิด Loading เมื่อพลาด

      // แจ้ง Error ให้ User ทราบ
      String message = "เกิดข้อผิดพลาด";
      if (e.code == 'user-not-found')
        message = "ไม่พบอีเมลนี้ในระบบ";
      else if (e.code == 'wrong-password')
        message = "รหัสผ่านไม่ถูกต้อง";
      else if (e.code == 'invalid-email')
        message = "รูปแบบอีเมลไม่ถูกต้อง";

      Get.snackbar(
        "เข้าสู่ระบบไม่สำเร็จ",
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

      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        Get.back();
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 1. ลอง Login เข้าไปก่อนเพื่อตรวจสถานะ
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      // 2. เช็คว่าเป็นการสร้างบัญชีใหม่ (New User) หรือไม่
      // additionalUserInfo?.isNewUser จะเป็น true ถ้าอีเมลนี้ไม่เคยมีในระบบมาก่อน (รูปที่ 5)
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        // ถ้าเป็น User ใหม่ที่เราไม่ต้องการให้เข้าถึง
        await userCredential.user?.delete(); // ลบบัญชีที่เพิ่งสร้างทิ้งทันที
        await googleSignIn.signOut();

        Get.back();
        Get.snackbar(
          "ไม่พบไอดีในระบบ",
          "กรุณาไปที่หน้า Signup เพื่อสมัครสมาชิกก่อนใช้งาน",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        Get.to(() => const Signup());
        return;
      }

      // ถ้าไม่ใช่ New User (แสดงว่ามีชื่อในระบบอยู่แล้วตามรูปที่ 5) ให้ไปหน้า Wrapper
      Get.back();
      Get.offAll(() => const Wrapper());
    } catch (e) {
      Get.back();
      print("Error: $e");
      Get.snackbar(
        "Login Failed",
        "เกิดข้อผิดพลาด: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("login")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: email,
              decoration: InputDecoration(hintText: "Enter email"),
            ),
            TextField(
              controller: password,
              decoration: InputDecoration(hintText: "Enter password"),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: (() => loginwithform()), child: Text("Login")),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: (() => Get.to(Signup())),
              child: Text("Signup"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: (() => Get.to(Forgot())),
              child: Text("Forgot password"),
            ),
            const SizedBox(height: 20),

            // เพิ่มปุ่ม Google Login
            ElevatedButton.icon(
              onPressed: () =>
                  loginwithgoogle(), // เรียกฟังก์ชัน Google Login ที่คุณเขียนไว้
              icon: const Icon(Icons.login_rounded), // หรือใส่โลโก้ Google
              label: const Text("Login with Google"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(
                  double.infinity,
                  50,
                ), 
              ),
            ),
          ],
        ),
      ),
    );
  }
}
