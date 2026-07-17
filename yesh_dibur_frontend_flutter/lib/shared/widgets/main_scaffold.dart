import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // הייבוא החדש של Riverpod
import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart'; // כדי לדעת אם מחובר או אורח
import 'guest_modal_bottom_sheet.dart'; // החלון של האורחים
import 'creation_bottom_sheet.dart'; // תפריט היצירה החדש שעשינו

// שינינו ל-ConsumerWidget כדי שנוכל להאזין ל-Providers
class MainScaffold extends ConsumerWidget {
  final Widget child;
  
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // הוספנו כאן את ref
    final String location = GoRouterState.of(context).uri.toString();
    
    int currentIndex = 0;
    if (location.startsWith('/search')) currentIndex = 1;
    if (location.startsWith('/notifications')) currentIndex = 3;
    if (location.startsWith('/chat')) currentIndex = 4;

    return Scaffold(
      body: child,
      // כפתור יצירה מרכזי בולט (+)
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          // הבדיקה החכמה שלנו: האם המשתמש מחובר?
          final authState = ref.read(authProvider);
          
          if (authState.value == null) {
            // אם הוא אורח - נקפיץ לו הצעת הרשמה
            GuestModalBottomSheet.show(context);
          } else {
            // אם הוא מחובר - נפתח לו את תפריט היצירה
            CreationBottomSheet.show(context);
          }
        },
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context, 
              icon: Icons.home_filled, 
              label: 'בית', 
              index: 0, 
              currentIndex: currentIndex, 
              route: '/',
            ),
            _buildNavItem(
              context, 
              icon: Icons.search, 
              label: 'חיפוש', 
              index: 1, 
              currentIndex: currentIndex, 
              route: '/search',
            ),
            const SizedBox(width: 48), // מרווח עבור ה-FAB המרכזי
            _buildNavItem(
              context, 
              icon: Icons.notifications, 
              label: 'התראות', 
              index: 3, 
              currentIndex: currentIndex, 
              route: '/notifications',
            ),
            _buildNavItem(
              context, 
              icon: Icons.mail, 
              label: 'צ\'אט', 
              index: 4, 
              currentIndex: currentIndex, 
              route: '/chat',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {
    required IconData icon, 
    required String label, 
    required int index, 
    required int currentIndex, 
    required String route
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;
    
    return InkWell(
      onTap: () {
        if (!isSelected) {
          context.go(route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}