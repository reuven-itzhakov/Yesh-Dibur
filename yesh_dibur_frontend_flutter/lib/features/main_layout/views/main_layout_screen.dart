import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  // רשימת המסכים (כרגע פלייסבולדרים פשוטים)
  final List<Widget> _screens = [
    const Center(child: Text('פיד ראשי (גילוי והקבוצות שלי)')),
    const Center(child: Text('חיפוש')),
    const Center(child: Text('מסך יצירת פוסט/קבוצה')),
    const Center(child: Text('התראות')),
    const Center(child: Text('תיבת הודעות (Inbox)')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.card,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.mutedForeground,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'ראשי'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'חיפוש'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'יצירה'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'התראות'),
          BottomNavigationBarItem(icon: Icon(Icons.mail_outline), label: 'הודעות'),
        ],
      ),
    );
  }
}