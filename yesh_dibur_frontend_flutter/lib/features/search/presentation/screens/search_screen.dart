import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/search_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/guest_modal_bottom_sheet.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // חסימת אורחים לפי האפיון
    if (authState.value == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('חיפוש')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              const Text('הצטרף לקהילה כדי לחפש ולגלות קבוצות ואנשים חדשים'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => GuestModalBottomSheet.show(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('הרשמה / התחברות', style: TextStyle(color: AppColors.white)),
              ),
            ],
          ),
        ),
      );
    }

    // ממשק למשתמשים מחוברים
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: (value) => ref.read(searchProvider.notifier).performSearch(value),
          decoration: InputDecoration(
            hintText: 'חיפוש קבוצות ואנשים...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
      body: Column(
        children: [
          // סרגל מסננים מהירים
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                FilterChip(label: const Text('מיקום'), onSelected: (_) {}),
                const SizedBox(width: 8),
                FilterChip(label: const Text('גיל'), onSelected: (_) {}),
                const SizedBox(width: 8),
                FilterChip(label: const Text('תחומי עניין'), onSelected: (_) {}),
              ],
            ),
          ),
          Expanded(
            child: searchState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : searchState.error != null
                    ? Center(child: Text(searchState.error!))
                    : (searchState.groups.isEmpty && searchState.users.isEmpty)
                        ? const Center(child: Text('הזן מילת חיפוש למעלה.'))
                        : ListView(
                            children: [
                              // תוצאות של קבוצות
                              if (searchState.groups.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('קבוצות', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                                ...searchState.groups.map((group) => ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: group.coverImage != null ? NetworkImage(group.coverImage!) : null,
                                    child: group.coverImage == null ? const Icon(Icons.group) : null,
                                  ),
                                  title: Text(group.name),
                                  subtitle: Text('${group.membersCount} חברים'),
                                  onTap: () {
                                    // TODO: מעבר למסך הקבוצה הפנימי
                                  },
                                )),
                              ],
                              
                              // תוצאות של משתמשים
                              if (searchState.users.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('אנשים', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                                ...searchState.users.map((user) => ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
                                    child: user.profileImageUrl == null ? const Icon(Icons.person) : null,
                                  ),
                                  title: Text(user.name),
                                  onTap: () {
                                    // TODO: מעבר לפרופיל המשתמש
                                  },
                                )),
                              ],
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}