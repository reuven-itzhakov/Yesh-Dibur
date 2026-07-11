import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart'; // נפתח כשתגדיר את פיירבייס
import 'package:yesh_dibur_frontend_flutter/firebase_options.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // השורות הבאות חיוניות לאתחול Firebase מול ה-Native (iOS/Android)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    // חובה לעטוף את האפליקציה ב-ProviderScope כדי לאפשר שימוש ב-Riverpod
    const ProviderScope(
      child: YeshDiburApp(),
    ),
  );
}

class YeshDiburApp extends StatelessWidget {
  const YeshDiburApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Yesh Dibur',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // הגדרה קשיחה של עברית ו-RTL לאפליקציה
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('he', 'IL'),
      ],
      locale: const Locale('he', 'IL'),
      routerConfig: appRouter,
    );
  }
}