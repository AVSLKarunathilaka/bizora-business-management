import 'package:flutter/material.dart';
import 'dashboard/dashboard_screen.dart';
import 'db/database_helper.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.database;
  
  runApp(const InvoiceExpenseApp());
}

class InvoiceExpenseApp extends StatelessWidget {
  const InvoiceExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Small Business Invoice & Expense Management System',

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color.fromARGB(255, 100, 249, 1)
      ),

      home: const DashboardScreen(),
    );
  }
}