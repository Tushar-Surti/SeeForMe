import 'package:flutter/material.dart';
import 'package:seeforme/language_service.dart';

class LanguageSelector extends StatefulWidget {
  final VoidCallback onLanguageChanged;

  const LanguageSelector({
    Key? key,
    required this.onLanguageChanged,
  }) : super(key: key);

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  String _currentLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final language = await LanguageService.getSelectedLanguage();
    if (mounted) {
      setState(() {
        _currentLanguage = language;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await LanguageService.showLanguageSelectionDialog(context);
        await _loadCurrentLanguage();
        widget.onLanguageChanged();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Color(0xFF6C63FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(0xFF6C63FF).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language,
              color: Color(0xFF6C63FF),
              size: 20,
            ),
            SizedBox(width: 6),
            Text(
              _currentLanguage,
              style: TextStyle(
                color: Color(0xFF3F3D9B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF6C63FF),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
} 