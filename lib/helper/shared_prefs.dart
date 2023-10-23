import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static late SharedPreferences _sharedPreferences;
  SharedPrefs._();

  static void setData(String key, var value) async {
    var data = SharedPrefs._();
    _sharedPreferences = await data._intialisePrefs();
    switch (value.runtimeType) {
      case int:
        _sharedPreferences.setInt(key, value);
        break;
      case bool:
        _sharedPreferences.setBool(key, value);
        break;
      case double:
        _sharedPreferences.setDouble(key, value);
        break;
      case String:
        _sharedPreferences.setString(key, value);
        break;
    }
  }

  /// Will return the entered type data
  /// if entered [key] data type is bool, then it'll try search the bool type in shared prefs
  /// [type] will be bool, int, double or String
  static Future<dynamic> getData(String key, Type type) async {
    var data = SharedPrefs._();
    _sharedPreferences = await data._intialisePrefs();
    dynamic res;
    switch (type) {
      case bool:
        res = _sharedPreferences.getBool(key);
        break;
      case int:
        res = _sharedPreferences.getInt(key);
        break;
      case double:
        res = _sharedPreferences.getDouble(key);
        break;
      case String:
        res = _sharedPreferences.getString(key);
        break;
    }
    return res;
  }

  Future<SharedPreferences> _intialisePrefs() async {
    return await SharedPreferences.getInstance();
  }
}
