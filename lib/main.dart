import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/toofast_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'themes/app_theme.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialización de Stripe
  Stripe.publishableKey = "pk_live_51TZMGeHsB3vaNXFwbCYvKHxysyMzRgoLWgqg0N0XYe85QdxK3NHzImbethJ0jhFPa5xpGnLMF1LUl09T8nzwJfxl001G0CKNHo"; // REEMPLAZAR

  await Firebase.initializeApp();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ToofastProvider(),
      child: const ToofastApp(),
    ),
  );
}

class ToofastApp extends StatefulWidget {
  const ToofastApp({super.key});

  @override
  State<ToofastApp> createState() => _ToofastAppState();
}

class _ToofastAppState extends State<ToofastApp> {
  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toofast',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigationScreen(),
    );
  }
}
