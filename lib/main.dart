import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ads.dart';
import 'home_screen.dart';
import 'sfx.dart';
import 'storage.dart';
import 'strings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await Storage.init();
  S.init(WidgetsBinding.instance.platformDispatcher.locale);
  Sfx.init();
  Ads.init();
  runApp(const AntitapApp());
}

class AntitapApp extends StatelessWidget {
  const AntitapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
      ),
      builder: (context, child) => Directionality(
        textDirection: S.ar ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
      home: const HomeScreen(),
    );
  }
}
