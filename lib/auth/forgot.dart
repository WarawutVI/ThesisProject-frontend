import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class Forgot extends StatefulWidget {
  const Forgot({super.key});

  @override
  State<Forgot> createState() => _ForgotState();
}

class _ForgotState extends State<Forgot> {
   TextEditingController email = TextEditingController();

  reset() async {
    if (email.text.trim().isEmpty) {
      Get.snackbar("แจ้งเตือน", "กรุณากรอกอีเมลก่อนครับ",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.amber,
          colorText: Colors.black);
      return;
    }

    try {
      // แสดง Loading ขณะรอ Firebase ส่งอีเมล
      Get.dialog(const Center(child: CircularProgressIndicator()),
          barrierDismissible: false);

      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email.text.trim());

      Get.back(); // ปิด Loading

      // แจ้งผู้ใช้ว่าสำเร็จ และพากลับหน้า Login
      Get.defaultDialog(
          title: "ส่งลิงก์สำเร็จ",
          middleText: "กรุณาตรวจสอบกล่องจดหมายในอีเมลของคุณ",
          textConfirm: "ตกลง",
          onConfirm: () {
            Get.back(); // ปิด Dialog
            Get.back(); // กลับไปหน้า Login
          });
    } on FirebaseAuthException catch (e) {
      Get.back(); // ปิด Loading
      
      // จัดการ Error ตามรหัสที่ Firebase ส่งมา
      String message = "เกิดข้อผิดพลาด กรุณาลองใหม่";
      if (e.code == 'user-not-found') {
        message = "ไม่พบอีเมลนี้ในระบบ";
      }
      
      Get.snackbar("ล้มเหลว", message,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Forgot password")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
          TextField(
            controller: email,
           decoration: InputDecoration(hintText: "Enter email"),
          ),
          ElevatedButton(onPressed: (()=>reset()), child: Text("Send link"))
          ],
        ),
      ),
    );;
  }
}