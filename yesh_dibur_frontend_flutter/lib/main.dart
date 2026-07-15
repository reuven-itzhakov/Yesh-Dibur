import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:yesh_dibur_frontend_flutter/core/theme/app_theme.dart';
import 'firebase_options.dart';

// הייבוא החדש של הראוטר שלנו
import 'core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: YeshDiburApp()));
}

class YeshDiburApp extends ConsumerWidget {
  const YeshDiburApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // אנו מאזינים לראוטר שהגדרנו דרך Riverpod
    final router = ref.watch(appRouterProvider);

    // משתמשים ב-MaterialApp.router במקום MaterialApp רגיל
    return MaterialApp.router(
      title: 'Yesh Dibur',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('he', 'IL'), 
      ],
      locale: const Locale('he', 'IL'),
      
      // חיבור חבילת הניווט לאפליקציה
      routerConfig: router,
    );
  }
}