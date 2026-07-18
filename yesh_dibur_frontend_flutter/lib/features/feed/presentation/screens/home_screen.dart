import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            onPressed: () {
              final authState = ref.read(authProvider);
              if (authState.value == null) {
                GuestModalBottomSheet.show(context);
              } else {
                context.push('/profile');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
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

    if (authState.value == null) {
      // חסימת אורחים - הקוד נשאר אותו דבר
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

    final feedState = ref.watch(myGroupsFeedProvider);
    
    return feedState.when(
      data: (threads) {
        return RefreshIndicator(
          onRefresh: () async {
            // רענון הפיד מחדש (מושך מלמעלה)
            ref.invalidate(myGroupsFeedProvider);
          },
          child: threads.isEmpty
              // משתמשים ב-ListView גם למצב ריק כדי לאפשר משיכה לרענון
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    const Center(child: Text('עדיין לא פרסמו פוסטים בקבוצות שלך.')),
                  ],
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: threads.length,
                  itemBuilder: (context, index) => ThreadCard(thread: threads[index]),
                ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              // עכשיו נראה בדיוק מה השגיאה שהשרת זרק!
              Text(
                'שגיאה מהשרת:\n$error', 
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('רענן עמוד'),
                onPressed: () => ref.invalidate(myGroupsFeedProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}