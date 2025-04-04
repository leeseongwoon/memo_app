import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/memo.dart';
import 'models/folder.dart';
import 'models/drawing.dart';
import 'providers/memo_provider.dart';
import 'providers/folder_provider.dart';
import 'providers/drawing_provider.dart';
import 'screens/memo_list_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
      appId: '1:XXXXXXXXXXXX:web:XXXXXXXXXXXXXXXXXXXXXXXX',
      messagingSenderId: 'XXXXXXXXXXXX',
      projectId: 'memo-app-bfad2',
      authDomain: 'memo-app-bfad2.firebaseapp.com',
      storageBucket: 'memo-app-bfad2.appspot.com',
    ),
  );
  
  // Hive 초기화
  await Hive.initFlutter();
  
  // 어댑터 등록
  Hive.registerAdapter(MemoAdapter());
  Hive.registerAdapter(FolderAdapter());
  Hive.registerAdapter(DrawingPointAdapter());
  Hive.registerAdapter(DrawingAdapter());
  
  // 박스 열기
  await Hive.openBox<Memo>('memos');
  await Hive.openBox<Folder>('folders');
  await Hive.openBox<Drawing>('drawings');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MemoProvider()),
        ChangeNotifierProvider(create: (_) => FolderProvider()),
        ChangeNotifierProvider(create: (_) => DrawingProvider()),
      ],
      child: MaterialApp(
        title: '메모장',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            primary: Colors.deepPurple,
            secondary: Colors.deepPurpleAccent,
            tertiary: Colors.amber,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Pretendard',
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: Colors.deepPurple),
            titleTextStyle: TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          cardTheme: CardTheme(
            elevation: 1.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: const MemoListScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
