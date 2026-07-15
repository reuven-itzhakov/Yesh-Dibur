import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onEditTapped(String currentName, String? currentBio) {
    setState(() {
      _isEditing = true;
      _nameController.text = currentName;
      _bioController.text = currentBio ?? '';
    });
  }

  void _onSaveTapped() async {
    final success = await ref.read(profileProvider.notifier).updateProfileDetails(
      _nameController.text.trim(), 
      _bioController.text.trim()
    );
    
    if (success && mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('הפרופיל עודכן בהצלחה!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('שגיאה בעדכון הפרופיל'), backgroundColor: Colors.red));
    }
  }

  void _onUpdateLocation() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('מעדכן מיקום...')));
    final success = await ref.read(profileProvider.notifier).sendLocationUpdate();
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('המיקום עודכן במערכת!'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('שגיאה בעדכון המיקום'), backgroundColor: Colors.red));
      }
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go('/register');
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('הפרופיל שלי'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'התנתק',
            onPressed: _logout,
          )
        ],
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('שגיאה בטעינת הפרופיל: $err')),
        data: (profile) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primary,
                  backgroundImage: profile.profileImageUrl != null ? NetworkImage(profile.profileImageUrl!) : null,
                  child: profile.profileImageUrl == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                ),
                const SizedBox(height: 24),
                
                if (_isEditing) ...[
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'שם מלא', filled: true, fillColor: AppTheme.muted),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'ביוגרפיה', filled: true, fillColor: AppTheme.muted),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(onPressed: _onSaveTapped, child: const Text('שמור שינויים')),
                      OutlinedButton(onPressed: () => setState(() => _isEditing = false), child: const Text('ביטול')),
                    ],
                  ),
                ] else ...[
                  Text(profile.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(profile.email, style: const TextStyle(color: AppTheme.mutedForeground)),
                  const SizedBox(height: 16),
                  Text(profile.bio ?? 'עוד לא כתבת כלום על עצמך...', textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('ערוך פרופיל'),
                    onPressed: () => _onEditTapped(profile.name, profile.bio),
                  ),
                ],
                
                const Divider(height: 48),
                ListTile(
                  leading: const Icon(Icons.location_on, color: AppTheme.primary),
                  title: const Text('עדכון מיקום נוכחי'),
                  subtitle: const Text('מסייע בהצגת קבוצות ופוסטים רלוונטיים באזורך'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _onUpdateLocation,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}