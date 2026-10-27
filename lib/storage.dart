import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static late SharedPreferences _p;

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
  }

  static int get best => _p.getInt('best') ?? 0;

  static Future<void> setBest(int v) async {
    await _p.setInt('best', v);
  }

  static bool get sound => _p.getBool('sound') ?? true;

  static Future<void> setSound(bool v) async {
    await _p.setBool('sound', v);
  }
}
