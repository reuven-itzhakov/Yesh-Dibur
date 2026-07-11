import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/thread_model.dart';
import '../providers/feed_provider.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // שני טאבים: הקבוצות שלי, ופיד גילוי
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
        title: const Text('יש דיבור'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'הקבוצות שלי'),
            Tab(text: 'גילוי'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FeedListView(provider: myGroupsFeedProvider),
          _FeedListView(provider: discoveryFeedProvider),
        ],
      ),
    );
  }
}

// ווידג'ט גנרי שמקבל את הספק המתאים (גילוי או הקבוצות שלי) ומציג את הרשימה
class _FeedListView extends ConsumerStatefulWidget {
  final AsyncNotifierProvider<dynamic, List<ThreadModel>> provider;

  const _FeedListView({required this.provider});

  @override
  ConsumerState<_FeedListView> createState() => _FeedListViewState();
}

class _FeedListViewState extends ConsumerState<_FeedListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // בודק אם הגענו לסוף הרשימה כדי לטעון את העמוד הבא
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (widget.provider == discoveryFeedProvider) {
        ref.read(discoveryFeedProvider.notifier).loadMore();
      } else {
        ref.read(myGroupsFeedProvider.notifier).loadMore();
      }
    }
  }

  Future<void> _onRefresh() async {
    if (widget.provider == discoveryFeedProvider) {
      await ref.read(discoveryFeedProvider.notifier).refresh();
    } else {
      await ref.read(myGroupsFeedProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(widget.provider);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: feedState.when(
        data: (threads) {
          if (threads.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 100),
                Center(child: Text('אין פוסטים להצגה כרגע.')),
              ],
            );
          }
          return ListView.builder(
            controller: _scrollController,
            itemCount: threads.length + 1, // הוספת אייטם ריק בסוף עבור מרווח או חיווי טעינה
            itemBuilder: (context, index) {
              if (index == threads.length) {
                return const SizedBox(height: 80); 
              }
              final thread = threads[index];
              return _ThreadCardBase(thread: thread);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          children: [
            const SizedBox(height: 100),
            Center(child: Text('שגיאה בטעינת הפיד:\n$error', textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}

// כרטיסייה פונקציונלית פשוטה להצגת הנתונים בלבד
class _ThreadCardBase extends StatelessWidget {
  final ThreadModel thread;

  const _ThreadCardBase({required this.thread});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.muted,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(thread.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(thread.groupName, style: const TextStyle(color: AppTheme.secondary, fontSize: 12)),
                    ],
                  ),
                ),
                if (thread.locationLabel != null)
                  Text(thread.locationLabel!, style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
              ],
            ),
            const SizedBox(height: 12),
            Text(thread.content),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(thread.isLiked ? Icons.favorite : Icons.favorite_border, 
                         color: thread.isLiked ? AppTheme.primary : null, size: 20),
                    const SizedBox(width: 4),
                    Text('${thread.likesCount}'),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 20),
                    const SizedBox(width: 4),
                    Text('${thread.commentsCount}'),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}