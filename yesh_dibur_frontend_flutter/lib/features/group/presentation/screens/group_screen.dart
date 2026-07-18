import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../feed/presentation/widgets/thread_card.dart';
import '../../data/models/group_model.dart';
// נניח שיש לנו Provider שיודע לשלוף קבוצה לפי ID (נבנה אותו בהמשך אם צריך)
// import '../../providers/group_details_provider.dart';

class GroupScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends ConsumerState<GroupScreen> {
  // משתנה דמי (Dummy) שמדמה קבוצה. בהמשך נמשוך זאת מהשרת בעזרת ה-groupId
  late GroupModel _group;

  @override
  void initState() {
    super.initState();
    // יצירת קבוצת דמי לתצוגה ראשונית
    _group = GroupModel(
      id: widget.groupId,
      name: 'קבוצה לדוגמה',
      description: 'זהו תיאור הקבוצה שהרגע יצרת בשרת. כאן חברי הקבוצה יוכלו לראות על מה מדובר.',
      coverImage: null, // אם יש תמונה, היא תוצג כאן
      membersCount: 1,
      interests: ['טכנולוגיה', 'כללי'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // הדר גולש (Sliver) עם תמונת הנושא
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _group.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                ),
              ),
              background: _group.coverImage != null
                  ? Image.network(_group.coverImage!, fit: BoxFit.cover)
                  : Container(color: AppColors.primary),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  // TODO: שיתוף קבוצה
                },
              ),
            ],
          ),

          // אזור מידע הקבוצה
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_group.membersCount} חברים',
                        style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: לוגיקת הצטרפות / עזיבת קבוצה
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('הצטרף לקבוצה', style: TextStyle(color: AppColors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_group.description ?? '', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('פוסטים מהקבוצה', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),

          // רשימת הפוסטים של הקבוצה בלבד
          // כרגע אנו שמים מקום ריק, אבל בהמשך נחבר לכאן קריאה לשרת לטובת משיכת פוסטים של קבוצה ספציפית
          SliverFillRemaining(
            child: Center(
              child: Text(
                'בקרוב נוסיף לכאן את הפוסטים של ${_group.name}...',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}