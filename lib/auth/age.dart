import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/widgets/language_toggle_button.dart';
import 'package:frontend/wrapper.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class Agepage extends StatefulWidget {
  final String uid;
  final String username;
  final String email;
  final String? gender;
  final String loginProvider;
  final bool isEnglish;

  const Agepage({
    super.key,
    required this.uid,
    required this.username,
    required this.email,
    this.gender,
    required this.loginProvider,
    this.isEnglish = true,
  });

  @override
  State<Agepage> createState() => _AgepageState();
}

class _AgepageState extends State<Agepage> {
  late FixedExtentScrollController _scrollController;
  late bool isEnglish;
  int selectedAge = 17;
  final List<int> ages = List.generate(86, (i) => i + 5); // 5–90
  final List<int> quickAges = [14, 17, 21, 30, 45];

  @override
  void initState() {
    super.initState();
    isEnglish = widget.isEnglish;
    _scrollController =
        FixedExtentScrollController(initialItem: ages.indexOf(selectedAge));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String t(String en, String th) => isEnglish ? en : th;

  void _selectQuickAge(int age) {
    setState(() => selectedAge = age);
    _scrollController.animateToItem(
      ages.indexOf(age),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _createAccount() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      await postdata(widget.uid, widget.username, widget.email, widget.gender, selectedAge, widget.loginProvider);

      Get.back();
      Get.offAll(() => const Wrapper());
    } catch (e) {
      Get.back();
      Get.snackbar(t("Error", "เกิดข้อผิดพลาด"), e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> postdata(String uid, String name, String email, String? gender, int? age, String loginProvider) async {
    try {
      var response = await http.post(
        Uri.parse('http://10.0.2.2:4000/users'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'firebase_uid': uid,
          'username': name,
          'email': email,
          'gender': gender,
          'age': age,
          'login_provider': loginProvider,
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
      backgroundColor: const Color(0xFFEEF8F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: LanguageToggleButton(
                  isEnglish: isEnglish,
                  onChanged: (v) => setState(() => isEnglish = v),
                  pillStyle: true,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t('How old are you?', 'คุณอายุเท่าไหร่?'),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t("We'll calibrate the model to your age range.",
                    "เราจะปรับโมเดลให้เหมาะกับช่วงอายุของคุณ"),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: CupertinoPicker.builder(
                  scrollController: _scrollController,
                  itemExtent: 54,
                  onSelectedItemChanged: (index) =>
                      setState(() => selectedAge = ages[index]),
                  selectionOverlay: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A9B6A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  childCount: ages.length,
                  itemBuilder: (context, index) {
                    final age = ages[index];
                    final isSelected = selectedAge == age;
                    return Center(
                      child: Text(
                        '$age',
                        style: TextStyle(
                          fontSize: isSelected ? 30 : 22,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFF1A7A50)
                              : Colors.grey[400],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: quickAges.map((age) {
                  final isSelected = selectedAge == age;
                  return GestureDetector(
                    onTap: () => _selectQuickAge(age),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFF1A7A50)
                            : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1A7A50)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$age',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A7A50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    t("Let's go!", "ไปเลย!"),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
