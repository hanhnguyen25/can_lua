import 'package:flutter/material.dart';

import 'theme.dart';
import 'weigh_screen.dart';

void main() => runApp(const CanApp());

class CanApp extends StatelessWidget {
  const CanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cân cà phê',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // Giảm 10% cỡ chữ so với cài đặt cỡ chữ của máy
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final heSo = (mq.textScaler.scale(10) / 10) * 0.9;
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(heSo)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeScreen(),
    );
  }
}

// Màn hình chính: chứa 2 phần, IndexedStack giữ nguyên số liệu khi chuyển qua lại
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;

  void _selectTab(int i) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => tab = i);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: tab,
      sizing: StackFit.expand,
      children: [
        WeighScreen(id: 0, currentTab: tab, onTab: _selectTab), // Cà tươi
        WeighScreen(id: 1, currentTab: tab, onTab: _selectTab), // Cà nhân
      ],
    );
  }
}
