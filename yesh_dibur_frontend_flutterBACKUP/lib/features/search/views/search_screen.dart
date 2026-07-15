import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchSubmit(String query) {
    ref.read(searchProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onSubmitted: _onSearchSubmit,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'חפש אנשים וקבוצות...',
            prefixIcon: const Icon(Icons.search, color: AppTheme.mutedForeground),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: AppTheme.mutedForeground),
              onPressed: () {
                _searchController.clear();
                _onSearchSubmit('');
              },
            ),
            filled: true,
            fillColor: AppTheme.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'אנשים'),
            Tab(text: 'קבוצות'),
          ],
        ),
      ),
      body: searchState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('שגיאה בחיפוש: $err')),
        data: (response) {
          return TabBarView(
            controller: _tabController,
            children: [
              // טאב אנשים
              response.users.isEmpty
                  ? const Center(child: Text('לא נמצאו אנשים תואמים.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: response.users.length,
                      separatorBuilder: (context, index) => const Divider(color: AppTheme.border),
                      itemBuilder: (context, index) {
                        final user = response.users[index];
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(user.locationLabel ?? 'מרחק לא ידוע'),
                          onTap: () {
                            // בהמשך: מעבר לפרופיל משתמש פומבי
                          },
                        );
                      },
                    ),
              // טאב קבוצות
              response.groups.isEmpty
                  ? const Center(child: Text('לא נמצאו קבוצות תואמות.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: response.groups.length,
                      separatorBuilder: (context, index) => const Divider(color: AppTheme.border),
                      itemBuilder: (context, index) {
                        final group = response.groups[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.primary,
                            child: Icon(Icons.group, color: Colors.white),
                          ),
                          title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${group.membersCount} חברים'),
                          trailing: group.isMember 
                              ? const Icon(Icons.check_circle, color: AppTheme.success) 
                              : null,
                          onTap: () {
                            // בהמשך: מעבר לעמוד קבוצה
                          },
                        );
                      },
                    ),
            ],
          );
        },
      ),
    );
  }
}