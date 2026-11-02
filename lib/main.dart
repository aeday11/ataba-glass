import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'core/admin.dart';
import 'core/config.dart';
import 'core/theme.dart';
import 'data/api.dart';
import 'state/library_provider.dart';
import 'state/location_provider.dart';
import 'state/player_provider.dart';
import 'state/store_provider.dart';
import 'ui/screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // إحصائية لوحة المطوّر: تاريخ أول تشغيل وعدد مرات التشغيل.
  await registerLaunch();

  // ملء الشاشة: إخفاء شريط الحالة وأزرار الهاتف السفلية (وضع غامق شامل)
  // — تظهر الأزرار بسحبة جانبية مؤقتة عند الحاجة.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // خدمة التشغيل في الخلفية + إشعار التحكم + أزرار شاشة القفل.
  await JustAudioBackground.init(
    androidNotificationChannelId: '${ApiConfig.appId}.audio.channel',
    androidNotificationChannelName: 'دمعه عشق',
    androidNotificationChannelDescription: 'تشغيل مقاطع الرواديد الحسينيين',
    androidNotificationIcon: 'mipmap/ic_launcher',
    androidNotificationOngoing: true,
  );

  final dio = Dio(
    BaseOptions(
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
    ),
  );
  final store = await StoreProvider.init(dio);

  runApp(RihalApp(store: store));
}

class RihalApp extends StatelessWidget {
  const RihalApp({super.key, required this.store});

  final StoreProvider store;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<StoreProvider>.value(value: store),
        ChangeNotifierProvider<PlayerProvider>(
          create: (_) => PlayerProvider(store),
        ),
        ChangeNotifierProvider<LibraryProvider>(
          create: (_) => LibraryProvider(createApi()),
        ),
        ChangeNotifierProvider<LocationProvider>(
          create: (_) => LocationProvider(store),
        ),
      ],
      child: Consumer<StoreProvider>(
        builder: (context, store, _) {
          // نطبّق الثيم المختار قبل بناء MaterialApp كي تأخذه كل الألوان.
          AppColors.applyPreset(store.themeId);
          return MaterialApp(
            title: 'دمعه عشق',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}
