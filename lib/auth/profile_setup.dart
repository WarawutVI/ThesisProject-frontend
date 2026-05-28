import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/widgets/language_toggle_button.dart';
import 'package:frontend/wrapper.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ProfileSetupPage extends StatefulWidget {
  final String uid;
  final String username;
  final String email;
  final String loginProvider;
  final bool isEnglish;

  const ProfileSetupPage({
    super.key,
    required this.uid,
    required this.username,
    required this.email,
    required this.loginProvider,
    this.isEnglish = true,
  });

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  String? selectedGender;
  int selectedAge = 17;
  late bool isEnglish;

  final List<int> ages = List.generate(86, (i) => i + 5);
  final List<int> quickAges = [14, 17, 21, 30, 45];
  late FixedExtentScrollController _scrollController;

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

  Future<void> _finish() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      await http.post(
        Uri.parse('http://10.0.2.2:4000/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebase_uid': widget.uid,
          'username': widget.username,
          'email': widget.email,
          'gender': selectedGender,
          'age': selectedAge,
          'login_provider': widget.loginProvider,
        }),
      );

      Get.back();
      Get.offAll(() => const Wrapper());
    } catch (e) {
      Get.back();
      print('Error saving profile: $e');
      Get.snackbar(t("Error", "เกิดข้อผิดพลาด"), e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Widget _buildGenderOption(String gender) {
    final isSelected = selectedGender == gender;
    final color =
        isSelected ? const Color(0xFF1A7A50) : const Color(0xFFCCCCCC);
    const double circleSize = 48;
    const double bodyWidth = 54;
    const double bodyHeight = 66;

    final label = gender == 'male'
        ? t('Male', 'ชาย')
        : gender == 'female'
            ? t('Female', 'หญิง')
            : t('Other', 'อื่นๆ');

    Widget body;
    if (gender == 'male') {
      body = CustomPaint(
          painter: _TrianglePainter(color: color, pointingDown: true),
          size: const Size(bodyWidth, bodyHeight));
    } else if (gender == 'female') {
      body = CustomPaint(
          painter: _TrianglePainter(color: color, pointingDown: false),
          size: const Size(bodyWidth, bodyHeight));
    } else {
      body = CustomPaint(
          painter: _DiamondPainter(color: color),
          size: const Size(bodyWidth, bodyHeight));
    }

    return GestureDetector(
      onTap: () => setState(() => selectedGender = gender),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(height: 8),
          body,
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t('Profile Setup', 'ตั้งค่าโปรไฟล์'),
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 14)),
                  LanguageToggleButton(
                    isEnglish: isEnglish,
                    onChanged: (v) => setState(() => isEnglish = v),
                    pillStyle: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Gender section
              Text(
                t("What's your gender?", 'คุณเป็นเพศอะไร?'),
                style: const TextStyle(
                  color: Color(0xFF1A7A50),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t('Helps us tune your voice analysis',
                    'ช่วยปรับการวิเคราะห์เสียงของคุณ ✨'),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildGenderOption('male')),
                  Container(width: 1, height: 140, color: Colors.grey[200]),
                  Expanded(child: _buildGenderOption('female')),
                  Container(width: 1, height: 140, color: Colors.grey[200]),
                  Expanded(child: _buildGenderOption('other')),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(color: Color(0xFFD0F0E4), thickness: 1.5),
              const SizedBox(height: 16),

              // Age section
              Text(
                t('How old are you?', 'คุณอายุเท่าไหร่?'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t("We'll calibrate the model to your age range.",
                    "เราจะปรับโมเดลให้เหมาะกับช่วงอายุของคุณ"),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 120,
                child: CupertinoPicker.builder(
                  scrollController: _scrollController,
                  itemExtent: 40,
                  onSelectedItemChanged: (index) =>
                      setState(() => selectedAge = ages[index]),
                  selectionOverlay: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0F0E4),
                      borderRadius: BorderRadius.circular(12),
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
                          fontSize: isSelected ? 24 : 18,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFF1A7A50)
                              : Colors.grey[400],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: quickAges.map((age) {
                  final isSelected = selectedAge == age;
                  return GestureDetector(
                    onTap: () => _selectQuickAge(age),
                    child: Container(
                      width: 42,
                      height: 42,
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
                            color:
                                isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _finish,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool pointingDown;

  const _TrianglePainter({required this.color, required this.pointingDown});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (pointingDown) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    } else {
      path.moveTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) =>
      old.color != color || old.pointingDown != pointingDown;
}

class _DiamondPainter extends CustomPainter {
  final Color color;

  const _DiamondPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DiamondPainter old) => old.color != color;
}
