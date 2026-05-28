import 'package:flutter/material.dart';

class LanguageToggleButton extends StatelessWidget {
  final bool isEnglish;
  final ValueChanged<bool> onChanged;
  final bool pillStyle;

  const LanguageToggleButton({
    super.key,
    required this.isEnglish,
    required this.onChanged,
    this.pillStyle = false,
  });

  static Widget _flag(bool english) => ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.asset(
          english
              ? 'assets/picture/usa_flag.png'
              : 'assets/picture/th_flag.jpg',
          width: 24,
          height: 16,
          fit: BoxFit.cover,
        ),
      );

  List<PopupMenuEntry<bool>> _items() => [
        PopupMenuItem<bool>(
          value: false,
          child: Row(
            children: [
              _flag(false),
              const SizedBox(width: 10),
              const Text('ไทย'),
            ],
          ),
        ),
        PopupMenuItem<bool>(
          value: true,
          child: Row(
            children: [
              _flag(true),
              const SizedBox(width: 10),
              const Text('English'),
            ],
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    if (pillStyle) {
      return PopupMenuButton<bool>(
        onSelected: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (_) => _items(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2A9B6A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _flag(isEnglish),
              const SizedBox(width: 6),
              Text(
                isEnglish ? 'EN' : 'TH',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return PopupMenuButton<bool>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => _items(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            isEnglish
                ? 'assets/picture/usa_flag.png'
                : 'assets/picture/th_flag.jpg',
            width: 28,
            height: 20,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
