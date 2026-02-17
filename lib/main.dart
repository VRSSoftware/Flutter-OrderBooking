import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vrs_erp/OrderBooking/order_booking.dart';
import 'package:vrs_erp/OrderBooking/orderbooking_booknow.dart';
import 'package:vrs_erp/catalog/catalog.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/dashboard/OrderDetails_page.dart';
import 'package:vrs_erp/dashboard/dashboard.dart';
import 'package:vrs_erp/models/CartModel.dart';
import 'package:vrs_erp/privacypolicy/deleteAccount.dart';
import 'package:vrs_erp/privacypolicy/privacypolicy.dart';
import 'package:vrs_erp/production/jobCardListScreen.dart';
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
import 'package:vrs_erp/stockReport/stockreportpage.dart';
import 'package:vrs_erp/viewOrder/TemptestPage.dart';
import 'package:vrs_erp/viewOrder/ViewSalesOrderReport.dart';
import 'package:vrs_erp/viewOrder/view_order.dart';
import 'package:vrs_erp/viewOrder/view_order_screen.dart';
import 'package:vrs_erp/viewOrder/view_order_screen_barcode.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  usePathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CartModel())],
      child: MyApp(),
    ),
  );
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
        primarySwatch: Colors.blue,
        progressIndicatorTheme: ProgressIndicatorThemeData(color: Colors.blue),
        checkboxTheme: CheckboxThemeData(
          checkColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(Colors.blue),
          fillColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.blue; // your desired background color when checked
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
        '/viewOrderBarcode': (context) => ViewOrderScreenBarcode(),
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
        '/production': (context) => JobCardListScreen(),
      },

      // home: SalesOrderInvoicePage(),
      // home: OrderDetailsPage123(),
      home: LoginScreen(),
      // home: SplashScreen(),
      // home: MdnsDiscoveryScreen(),
    );
  }
}
