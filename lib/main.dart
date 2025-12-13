import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/auth_model.dart';
import 'models/product.dart';
import 'models/bill_item.dart';
import 'models/bill.dart';
import 'models/user_session.dart';
import 'models/otp_verification.dart';
import 'models/cloud_backup_settings.dart';
import 'services/auth_service.dart';
import 'services/product_service.dart';
import 'services/billing_service.dart';
import 'services/openfoodfacts_service.dart';
import 'providers/auth_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/billing_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    // REPLACE THIS:
    url: 'https://nyxomlecmybisraavfan.supabase.co',

    // REPLACE THIS with the "anon" key from the dashboard:
    anonKey: 'sb_publishable_SNZVGrF5fO3qLuP2binnmg_4X1qIYZ-',
  );

  await Hive.initFlutter();

  Hive.registerAdapter(AuthModelAdapter());
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(BillItemAdapter());
  Hive.registerAdapter(BillAdapter());
  Hive.registerAdapter(UserSessionAdapter());
  Hive.registerAdapter(OtpVerificationAdapter());
  Hive.registerAdapter(CloudBackupSettingsAdapter());

  final authService = AuthService();
  final productService = ProductService();
  final billingService = BillingService();
  final apiService = OpenFoodFactsService();

  await authService.init();
  await productService.init();
  await billingService.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(
            create: (_) => InventoryProvider(productService, apiService)),
        ChangeNotifierProvider(
            create: (_) => BillingProvider(billingService, productService)),
      ],
      child: const BharatStoreApp(),
    ),
  );
}

class BharatStoreApp extends StatelessWidget {
  const BharatStoreApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'BharatStore',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
