import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // הקובץ שהשגת מ-Firebase

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  // אתחול Firebase בצורה בטוחה בהתאם לפלטפורמה
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: YeshDiburApp()));
}

// ... המשך המחלקה YeshDiburApp ללא שינוי כרגע

class YeshDiburApp extends ConsumerWidget {
  const YeshDiburApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // בהמשך ניקח את הראוטר מתוך ה-Provider שלו
    // final router = ref.watch(appRouterProvider);

    return MaterialApp(
      title: 'Yesh Dibur',
      debugShowCheckedModeBanner: false,
      
      // הגדרות תמיכה בעברית וכיווניות (RTL)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('he', 'IL'), // הגדרת עברית כשפת האם של האפליקציה
      ],
      locale: const Locale('he', 'IL'),

      // בהמשך נחבר את העיצוב (Theme) שלנו
      // theme: AppTheme.lightTheme,
      
      // כרגע נשים דף זמני עד שנקים את ה-go_router
      home: const Scaffold(
        body: Center(
          child: Text(
            'יש דיבור - יוצאים לדרך!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      
      // בהמשך נשנה ל:
      // routerConfig: router,
    );
  }
}