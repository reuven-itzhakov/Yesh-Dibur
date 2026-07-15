import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/errors/exceptions.dart';
import '../providers/thread_details_provider.dart';
import '../repositories/thread_repository.dart';

class ThreadDetailsScreen extends ConsumerStatefulWidget {
  final String threadId;
  const ThreadDetailsScreen({super.key, required this.threadId});

  @override
  ConsumerState<ThreadDetailsScreen> createState() => _ThreadDetailsScreenState();
}

class _ThreadDetailsScreenState extends ConsumerState<ThreadDetailsScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() async {
    final success = await ref.read(commentsProvider(widget.threadId).notifier).addComment(_commentController.text);
    if (success && mounted) {
      _commentController.clear();
      FocusScope.of(context).unfocus(); // הורדת המקלדת
    } else {
      final errorState = ref.read(commentsProvider(widget.threadId));
      if (errorState.hasError) {
        final err = errorState.error;
        final msg = err is ValidationException ? 'שגיאת וולידציה:\n${err.errors}' : err.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    }
  }

  void _toggleLike() async {
    try {
      await ref.read(threadRepositoryProvider).toggleLike(widget.threadId);
      // מרענן את נתוני הפוסט כדי לשקף את הלייק החדש
      ref.invalidate(threadDetailsProvider(widget.threadId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('שגיאה בעדכון לייק'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final threadAsync = ref.watch(threadDetailsProvider(widget.threadId));
    final commentsAsync = ref.watch(commentsProvider(widget.threadId));

    return Scaffold(
      appBar: AppBar(title: const Text('דיון')),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // הצגת הפוסט הראשי
                SliverToBoxAdapter(
                  child: threadAsync.when(
                    loading: () => const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
                    error: (err, _) => Padding(padding: const EdgeInsets.all(20), child: Text('שגיאה בטעינת הפוסט: $err')),
                    data: (thread) => Card(
                      margin: const EdgeInsets.all(16),
                      color: AppTheme.muted,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(thread.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(thread.content, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(thread.isLiked ? Icons.favorite : Icons.favorite_border, color: thread.isLiked ? AppTheme.primary : null),
                                  onPressed: _toggleLike,
                                ),
                                Text('${thread.likesCount} לייקים'),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: Divider()),
                // הצגת התגובות
                commentsAsync.when(
                  loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                  error: (err, _) => SliverToBoxAdapter(child: Center(child: Text('שגיאה: $err'))),
                  data: (comments) {
                    if (comments.isEmpty) {
                      return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text('אין תגובות עדיין. היה הראשון להגיב!'))));
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final comment = comments[index];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person, size: 20)),
                            title: Text(comment.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(comment.content),
                          );
                        },
                        childCount: comments.length,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // שורת כתיבת התגובה למטה
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.card,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'הוסף תגובה...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.primary),
                    onPressed: _submitComment,
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}