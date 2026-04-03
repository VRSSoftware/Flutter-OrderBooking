import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vrs_erp/AI/AI_Home_Screen.dart';
import 'package:vrs_erp/AI/AI_Test.dart';
import 'package:vrs_erp/AI/AI_chat_report_web.dart/ai_chat_report_web.dart';
import 'package:vrs_erp/AI/AI_Image.dart';
import 'package:vrs_erp/Masters/Customer/Customer.dart';
import 'package:vrs_erp/Masters/Design/Design_Master.dart';
import 'package:vrs_erp/OrderBooking/order_booking.dart';
import 'package:vrs_erp/OrderBooking/orderbooking_booknow.dart';
import 'package:vrs_erp/Reports/Customer/customer.dart';
import 'package:vrs_erp/Reports/Ledger/ledgerReport.dart';
import 'package:vrs_erp/Reports/Order/Order.dart';
import 'package:vrs_erp/Reports/Payable/PayableReport.dart';
import 'package:vrs_erp/Reports/Production/Production.dart';
import 'package:vrs_erp/Reports/Receivable/ReceivableReport.dart';
import 'package:vrs_erp/Reports/Report_Home_Screen.dart';
import 'package:vrs_erp/Reports/Sales/SalesAnalysis.dart';
import 'package:vrs_erp/Reports/Stock/Stock.dart';
import 'package:vrs_erp/catalog/catalog.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/dashboard/OrderDetails_page.dart';
import 'package:vrs_erp/dashboard/customerOrderDetailsPage.dart';
import 'package:vrs_erp/dashboard/dashboard.dart';
import 'package:vrs_erp/firebase_options.dart';
import 'package:vrs_erp/models/CartModel.dart';
import 'package:vrs_erp/privacypolicy/deleteAccount.dart';
import 'package:vrs_erp/privacypolicy/privacypolicy.dart';
import 'package:vrs_erp/production/JobCard_cutting/jobCardListScreen.dart';
import 'package:vrs_erp/production/production_home_screen.dart';
import 'package:vrs_erp/register/packingRegisterScreen.dart';
import 'package:vrs_erp/register/register.dart';
import 'package:vrs_erp/catalog/catalog_screen.dart';
import 'package:vrs_erp/register/saleBillRegister.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';

import 'package:vrs_erp/screens/home_screen.dart';
import 'package:vrs_erp/screens/login_screen.dart';
import 'package:vrs_erp/screens/mdns/MdnsDiscoveryScreen.dart';
import 'package:vrs_erp/screens/packing/packing_order_screen.dart';
import 'package:vrs_erp/screens/sale_bill/sale_bill_order_screen.dart';
import 'package:vrs_erp/screens/splash_screen.dart';
import 'package:vrs_erp/services/notification_service.dart';
import 'package:vrs_erp/stockReport/stockreportpage.dart';
import 'package:vrs_erp/viewOrder/TemptestPage.dart';
import 'package:vrs_erp/viewOrder/ViewSalesOrderReport.dart';
import 'package:vrs_erp/viewOrder/view_order.dart';
import 'package:vrs_erp/viewOrder/view_order_screen.dart';
import 'package:vrs_erp/viewOrder/view_order_screen2.dart';
import 'package:vrs_erp/viewOrder/view_order_screen_barcode.dart';
import 'package:vrs_erp/viewOrder/view_order_screen_barcode2.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();
  await _loadBaseUrlFromPrefs();
  usePathUrlStrategy();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CartModel())],
      child: MyApp(),
    ),
  );
}

Future<void> _loadBaseUrlFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final savedUrl = prefs.getString('base_url');

  if (savedUrl != null && savedUrl.isNotEmpty) {
    AppConstants.BASE_URL = savedUrl;
    print("✅ Loaded URL from SharedPreferences: $savedUrl");
  } else {
    print("ℹ️ Using default URL: ${AppConstants.BASE_URL}");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VRS ERP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        // primarySwatch: AppColors.primaryColor
        primaryColor: const Color(0xFF072F5F),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: AppColors.primaryColor,
        ),
        checkboxTheme: CheckboxThemeData(
          checkColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(AppColors.primaryColor),
          fillColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors
                  .primaryColor; // your desired background color when checked
            }
            return Colors.grey.shade300; // color when unchecked
          }),
          // fillColor: MaterialStateProperty.all(Colors.blue),
        ),
      ),
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/catalog': (context) => CatalogScreen(),
        '/catalogpage': (context) => CatalogPage(),
        '/orderbooking': (context) => OrderBookingScreen(),
        '/orderpage': (context) => OrderPage(),
        '/viewOrders': (context) => ViewOrderScreens(),
        '/viewOrder': (context) => ViewOrderScreen(),
        '/viewOrder2': (context) => ViewOrderScreen2(),
        '/viewOrderBarcode': (context) => ViewOrderScreenBarcode(),
        '/viewOrderBarcode2': (context) => ViewOrderScreenBarcode2(),
        '/registerOrders': (context) => RegisterPage(),
        '/stockReport': (context) => StockReportPage(),
        '/dashboard': (context) => OrderSummaryPage(),
        '/deleteAccount': (context) => DeleteAccountPage(),
        '/setting': (context) => PrivacyPolicyPage(),
        '/drawer': (context) => DrawerScreen(),
        '/packingOrders': (context) => PackingPage(),
        '/packingBooking': (context) => PackingBookingScreen(),
        '/SaleBillBookingScreen': (context) => SaleBillBookingScreen(),
        '/saleBillRegister': (context) => SaleBillRegisterPage(),
        '/production': (context) => ProductionHomeScreen(),
        '/productionhomescreen': (context) => JobCardListScreen(),
        '/reportHomeScreen': (context) => ReportHomeScreen(),
        '/salesAnalysis': (context) => SalesAnalysis(),
        '/ProductionAnalysis': (context) => GarmentProductionAnalysis(),
        '/CustomerAnalysis': (context) => CustomerAnalysis(),
        '/StockAnalysis': (context) => StockAnalysis(),
        '/OrderAnalysis': (context) => OrderAnalysis(),

        '/image': (context) => FabricToGarmentGenerator(),
        '/vrsai': (context) => AIHomeScreen(),
        '/testAI': (context) => FashionDesignerScreen(),
        '/design': (context) => DesignMaster(),
        '/customer': (context) => CustomerMaster(),
        '/ai_chat_reports': (context) => aiChatReportWeb(),
        '/payable': (context) => PayableReport(),
        '/receivable': (context) => ReceivableReport(),
        '/ledger': (context) => LedgerReport(),
      },

      // home: SalesOrderInvoicePage(),
      // home: OrderDetailsPage123(),
      home: LoginScreen(),
      // home: SplashScreen(),
      // home: MdnsDiscoveryScreen(),
    );
  }
}
