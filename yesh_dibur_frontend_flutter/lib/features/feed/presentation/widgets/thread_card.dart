import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/thread_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/guest_modal_bottom_sheet.dart';

class ThreadCard extends ConsumerWidget {
  final ThreadModel thread;

  const ThreadCard({super.key, required this.thread});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // בדיקה האם המשתמש מחובר כדי לאפשר אינטראקציות
    final isGuest = ref.watch(authProvider).value == null;

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.75, // תופס 75% מגובה המסך
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.textPrimary, // צבע רקע ברירת מחדל
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // שכבה 1: רקע הפוסט (תמונה או צבע)
          _buildBackground(),
          
          // שכבה 2: שכבת ההגנה לטקסט (Scrim) עולה מהתחתית
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.bottomScrim,
            ),
          ),
          
          // שכבה 3: תוכן הפוסט
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // חלק עליון: פרטי קבוצה ואפשרויות
                  _buildHeader(context),
                  
                  const Spacer(), // דוחף את הטקסט למרכז/תחתית
                  
                  // מרכז: טקסט הפוסט
                  Text(
                    thread.content,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // תחתית: כפתורי אינטראקציה
                  _buildActions(context, isGuest),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    if (thread.bgType == 'image' && thread.bgValue.isNotEmpty) {
      return Image.network(
        thread.bgValue,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => 
            Container(color: AppColors.primary),
      );
    } else {
      // הנחה שהצבע מגיע בפורמט Hex, נשתמש בצבע ראשי כגיבוי בינתיים
      return Container(color: AppColors.primary);
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.white.withOpacity(0.2),
          backgroundImage: thread.groupCover != null 
              ? NetworkImage(thread.groupCover!) 
              : null,
          child: thread.groupCover == null 
              ? const Icon(Icons.group, color: AppColors.white, size: 20) 
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                thread.groupName,
                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'מאת ${thread.authorName}',
                style: TextStyle(color: AppColors.white.withOpacity(0.8), fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppColors.white),
          onPressed: () {
            // TODO: פתיחת תפריט אפשרויות (דיווח, חסימה)
          },
        )
      ],
    );
  }

  Widget _buildActions(BuildContext context, bool isGuest) {
    return Row(
      children: [
        _ActionIcon(
          icon: thread.isLikedByMe ? Icons.favorite : Icons.favorite_border,
          color: thread.isLikedByMe ? Colors.red : AppColors.white,
          count: thread.likesCount,
          onTap: () {
            if (isGuest) {
              GuestModalBottomSheet.show(context);
            } else {
              // TODO: קריאה ל-Provider של לייקים (Optimistic UI)
            }
          },
        ),
        const SizedBox(width: 24),
        _ActionIcon(
          icon: Icons.chat_bubble_outline,
          color: AppColors.white,
          count: thread.commentsCount,
          onTap: () {
            if (isGuest) {
              GuestModalBottomSheet.show(context);
            } else {
              // TODO: מעבר למסך הפוסט המורחב (תגובות)
            }
          },
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.share, color: AppColors.white),
          onPressed: () {
            // TODO: פתיחת חלון שיתוף
          },
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}