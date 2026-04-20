import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/wrapper.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController name = TextEditingController();
  TextEditingController surname = TextEditingController();

  signup_google() async {
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
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        String displayName = user.displayName?.trim() ?? "Unknown User";
        print(displayName);
        List<String> nameParts = displayName.split(' ');
        String fname = nameParts[0];
        String sname = nameParts.length > 1
            ? nameParts.sublist(1).join(' ')
            : "";
        // await postdata(user.uid,fname, sname, user.email ?? "");
      }

      await FirebaseAuth.instance.signInWithCredential(credential);

      Get.back();
      Get.offAll(() => Wrapper());
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

  sigup_email() async {

    if (email.text.trim().isEmpty ||password.text.isEmpty ||name.text.isEmpty ||surname.text.isEmpty) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณากรอกข้อมูลให้ครบถ้วน",
        backgroundColor: Colors.amber,
      );
      return;
    }
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text,
          );
      String? uid = userCredential.user?.uid;
      // if(uid!= null){
      //   await postdata(uid,name.text,surname.text,email.text.trim());
      // }
      print(uid);

      Get.back(); 
      Get.offAll(() => const Wrapper());
    } on FirebaseAuthException catch (e) {
      Get.back(); 
      String message = "สมัครสมาชิกไม่สำเร็จ";
      if (e.code == 'email-already-in-use') {
        message = "อีเมลนี้ถูกใช้งานไปแล้ว";
      } else if (e.code == 'weak-password') {
        message = "รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร";
      } else if (e.code == 'invalid-email') {
        message = "รูปแบบอีเมลไม่ถูกต้อง";
      }

      Get.snackbar(
        "เกิดข้อผิดพลาด",
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      Get.snackbar("Error", e.toString());
    }
  }

  postdata(String uid, String name, String surname, String email) async {
    try {
      var response = await http.post(
        Uri.parse('http://10.0.2.2:3000/users'), //http://10.0.2.2:3000/users
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'uid': uid,
          'name': name,
          'surname': surname,
          'email': email,
        }),
      );
      print(response.statusCode);
      if (response.statusCode == 200) {
        print("complete sign up");
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SignUp")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(hintText: "Enter name"),
            ),
            TextField(
              controller: surname,
              decoration: const InputDecoration(hintText: "Enter surname"),
            ),
            TextField(
              controller: email,
              decoration: InputDecoration(hintText: "Enter email"),
            ),
            TextField(
              controller: password,
              decoration: InputDecoration(hintText: "Enter password"),
            ),
            ElevatedButton(
              onPressed: (() => sigup_email()),
              child: Text("Signup"),
            ),
            ElevatedButton.icon(
              onPressed: () => signup_google(),
              icon: const Icon(Icons.login_rounded),
              label: const Text("sign up with Google"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
