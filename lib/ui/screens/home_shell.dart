import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ataba_screen.dart';
import 'mawalid_screen.dart';
import 'my_library_screen.dart';
import 'reciters_screen.dart';
import 'settings_screen.dart';
import '../widgets/glass.dart';
import '../widgets/mini_player.dart';

/// الهيكل الرئيسي: العتبة — الموالد — اللطميات — مكتبتي — الضبط
/// مع شريط تنقل زجاجي عائم.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    AtabaScreen(),
    MawalidScreen(),
    RecitersScreen(),
    MyLibraryScreen(),
    SettingsScreen(),
  ];

  static const _items = [
    (icon: Icons.auto_awesome_rounded, label: 'العتبة'),
    (icon: Icons.cake_rounded, label: 'الموالد'),
    (icon: Icons.library_music_rounded, label: 'اللطميات'),
    (icon: Icons.workspace_premium_outlined, label: 'مكتبتي'),
    (icon: Icons.tune_rounded, label: 'الضبط'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermission();
    });
  }

  Future<void> _requestNotificationPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final status = await Permission.notification.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        await Permission.notification.request();
      }
    } catch (_) {
      // نتجاهل فشل الطلب.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AtabaBackground(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: _screens,
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: GlassBottomBar(
              index: _index,
              onSelect: (value) => setState(() => _index = value),
              items: _items,
            ),
          ),
        ],
      ),
    );
  }
}
