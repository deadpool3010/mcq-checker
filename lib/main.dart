import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/mcq_provider.dart';

void main() {
  print('🚀 APP STARTING - Main function called');
  runApp(const MCQCheckerApp());
}

class MCQCheckerApp extends StatelessWidget {
  const MCQCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    print(' MCQCheckerApp build method called');
    return ChangeNotifierProvider(
      create: (context) {
        print('🚀 Creating MCQProvider...');
        final provider = MCQProvider();
        
        print('🔧 Calling autoInitialize...');
        provider.autoInitialize(); 
        
        print('📊 After autoInitialize - isInitialized: ${provider.isInitialized}');
        
        // Backup auto-refresh triggers for complete app restart
  
     
        
        
        return provider;
      },
      child: MaterialApp(
        title: 'MCQ Checker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            shape: CircleBorder(),
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}