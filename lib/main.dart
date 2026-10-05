import 'package:flutter/material.dart';
import 'models/user_data.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'services/purchase_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
  await PurchaseService.instance.init();

  final UserData? savedUser = StorageService.instance.getUserData();

  runApp(VioraApp(initialUser: savedUser));
}

class VioraApp extends StatelessWidget {
  final UserData? initialUser;
  const VioraApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: initialUser != null
          ? DashboardScreen(data: initialUser!)
          : const HomeScreen(),
    );
  }
}
