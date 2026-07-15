import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/discovery_feed_provider.dart';
import '../../providers/my_groups_feed_provider.dart';
import '../widgets/thread_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/guest_modal_bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('יש דיבור', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
        centerTitle: false,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'פיד גילוי'),
            Tab(text: 'הקבוצות שלי'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _DiscoveryTab(),
          const _MyGroupsTab(),
        ],
      ),
    );
  }
}

// === טאב פיד גילוי ===
class _DiscoveryTab extends ConsumerStatefulWidget {
  const _DiscoveryTab();

  @override
  ConsumerState<_DiscoveryTab> createState() => _DiscoveryTabState();
}

class _DiscoveryTabState extends ConsumerState<_DiscoveryTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // אם המשתמש הגיע קרוב לתחתית המסך (מרחק של 200 פיקסלים), נמשוך עוד
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(discoveryFeedProvider.notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(discoveryFeedProvider);

    return feedState.when(
      data: (threads) {
        if (threads.isEmpty) {
          return const Center(child: Text('אין פוסטים להציגה כרגע.'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            // ריענון מחדש של כל הפיד
            ref.invalidate(discoveryFeedProvider);
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            itemCount: threads.length + 1, // +1 עבור אינדיקטור הטעינה בתחתית
            itemBuilder: (context, index) {
              if (index == threads.length) {
                // המשתמש הגיע לסוף הרשימה, נציג טעינה אם יש עוד נתונים
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return ThreadCard(thread: threads[index]);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            const Text('אירעה שגיאה בטעינת הפיד.'),
            TextButton(
              onPressed: () => ref.invalidate(discoveryFeedProvider),
              child: const Text('נסה שוב'),
            ),
          ],
        ),
      ),
    );
  }
}

// === טאב הקבוצות שלי ===
class _MyGroupsTab extends ConsumerWidget {
  const _MyGroupsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // חסימת הגישה לאורחים
    if (authState.value == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text('הצטרף לקהילה כדי לראות את הקבוצות שלך', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => GuestModalBottomSheet.show(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('הרשמה / התחברות', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      );
    }

    // אם המשתמש מחובר, נציג את הפיד בדיוק כמו פיד הגילוי
    final feedState = ref.watch(myGroupsFeedProvider);
    // (כאן אפשר לממש ScrollController זהה לזה שבפיד הגילוי כדי למשוך פוסטים נוספים)
    // כרגע נציג רשימה פשוטה כדי לא לשכפל קוד בדוגמה זו:
    
    return feedState.when(
      data: (threads) {
        if (threads.isEmpty) {
          return const Center(child: Text('עדיין לא הצטרפת לקבוצות. חפש קבוצות חדשות!'));
        }
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: threads.length,
          itemBuilder: (context, index) => ThreadCard(thread: threads[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const Center(child: Text('שגיאה בטעינת הקבוצות שלך.')),
    );
  }
}