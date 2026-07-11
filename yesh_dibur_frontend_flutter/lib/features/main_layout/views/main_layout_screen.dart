import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../feed/views/feed_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  // רשימת המסכים (מסך הפיד הוכנס לאינדקס 0)
  final List<Widget> _screens = [
    const FeedScreen(), // הוחלף מהפלייסבולדר הקודם
    const Center(child: Text('חיפוש')),
    const Center(child: Text('מסך יצירת פוסט/קבוצה')),
    const Center(child: Text('התראות')),
    const Center(child: Text('תיבת הודעות (Inbox)')),
  ];
// מתוך הקובץ _MainLayoutScreenState
  void _onItemTapped(int index) {
    if (index == 2) {
      _showCreateModal();
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _showCreateModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.post_add, color: AppTheme.primary, size: 30),
                title: const Text('יצירת פוסט חדש', style: TextStyle(fontSize: 18)),
                onTap: () {
                  context.pop();
                  context.push('/create-thread'); // פותח את מסך יצירת הפוסט
                },
              ),
              const Divider(color: AppTheme.border),
              ListTile(
                leading: const Icon(Icons.group_add, color: AppTheme.secondary, size: 30),
                title: const Text('יצירת קבוצה חדשה', style: TextStyle(fontSize: 18)),
                onTap: () {
                  context.pop(); // סוגר את התפריט התחתון
                  context.push('/create-group'); // עובר למסך היצירה שבנינו
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // שים לב לעדכון של שורת ה-onTap בתוך ה-BottomNavigationBar:
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped, // שימוש בפונקציה החדשה שלנו
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