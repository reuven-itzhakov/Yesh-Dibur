import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ניהול המצב של הטאב הנוכחי שנבחר בתפריט
final currentTabProvider = StateProvider<int>((ref) => 0);

class MainLayoutScreen extends ConsumerWidget {
  const MainLayoutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentTabProvider);

    // רשימת המסכים האמיתיים שיוצגו (כרגע עם Placeholders עד שנבנה אותם)
    final List<Widget> screens = [
      const Center(child: Text('מסך הבית (פיד)')), // אינדקס 0: בית
      const Center(child: Text('מסך גילוי (חיפוש)')), // אינדקס 1: גילוי
      const SizedBox.shrink(), // אינדקס 2: שומר מקום לכפתור היצירה (לא משמש כמסך)
      const Center(child: Text('מסך פעילות (התראות)')), // אינדקס 3: פעילות
      const Center(child: Text('מסך צ\'אט')), // אינדקס 4: צ'אט
    ];

    return Scaffold(
      body: screens[currentIndex],
      
      // כפתור הפלוס המרחף (Electric Coral)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // כאן נפתח מודל תחתון (BottomSheet) ליצירת פוסט או קבוצה
        },
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 8, // --shadow-fab
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      
      // מיקום הכפתור המרחף במרכז התפריט התחתון
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // התפריט התחתון עצמו
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Theme.of(context).cardColor,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, ref, index: 0, icon: Icons.home_outlined, label: 'בית'),
              _buildNavItem(context, ref, index: 1, icon: Icons.search, label: 'גילוי'),
              const SizedBox(width: 48), // מרווח פיזי עבור כפתור הפלוס
              _buildNavItem(context, ref, index: 3, icon: Icons.notifications_none, label: 'פעילות', badgeCount: 3),
              _buildNavItem(context, ref, index: 4, icon: Icons.chat_bubble_outline, label: 'צ\'אט', badgeCount: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ווידג'ט עזר לבניית כפתורי התפריט (כולל תמיכה בבאדג'ים אדומים)
  Widget _buildNavItem(BuildContext context, WidgetRef ref, {
    required int index, 
    required IconData icon, 
    required String label, 
    int? badgeCount,
  }) {
    final isSelected = ref.watch(currentTabProvider) == index;
    final color = isSelected ? Theme.of(context).primaryColor : Colors.grey;

    return GestureDetector(
      onTap: () => ref.read(currentTabProvider.notifier).state = index,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 26),
              if (badgeCount != null && badgeCount > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4C4C), // --destructive
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}