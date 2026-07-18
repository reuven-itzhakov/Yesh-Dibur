import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('הפרופיל שלי'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // בהמשך נוסיף כאן מסך הגדרות (התראות, שפה, מחיקת חשבון)
            },
          ),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            // מקרה קצה במידה ואורח איכשהו הגיע לכאן
            return const Center(child: Text('אינך מחובר למערכת.'));
          }

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // אזור תמונת פרופיל ושם משתמש
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: user.profileImageUrl != null 
                          ? NetworkImage(user.profileImageUrl!) 
                          : null,
                      child: user.profileImageUrl == null 
                          ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // תחומי עניין
              const Text(
                'תחומי העניין שלי',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: user.interests.map((interest) {
                  return Chip(
                    label: Text(interest),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    labelStyle: const TextStyle(color: AppColors.primary),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // כפתורי פעולה
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('עריכת פרופיל'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // מעבר לעריכת הפרופיל
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('התנתקות', style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  // הקפצת חלון אישור לפני התנתקות
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('התנתקות'),
                      content: const Text('האם אתה בטוח שברצונך להתנתק?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('ביטול'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('התנתק', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true && context.mounted) {
                    await ref.read(authProvider.notifier).logout();
                    context.go('/'); // חזרה למסך הבית (כאורח)
                  }
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('שגיאה בטעינת הפרופיל: $error')),
      ),
    );
  }
}