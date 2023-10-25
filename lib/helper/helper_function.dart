import 'shared_prefs.dart';

class HelperFunction {
  // keys
  static String userLoggedInKey = 'LOGGEDINKEY';
  static String userNameKey = 'USERNAMEKEY';
  static String userEmailKey = 'USEREMAILKEY';

  // saving the data to SF
  static saverUserLoggedInStatus(bool isUserLoggedIn) {
    SharedPrefs.setData(userLoggedInKey, isUserLoggedIn);
  }

  static saverUserNameSF(String userName) {
    SharedPrefs.setData(userNameKey, userName);
  }

  static saverUserEmailSF(String userEmail) async {
    SharedPrefs.setData(userEmailKey, userEmail);
  }

  // getting the data from SF
  static Future<bool?> getUserLoggedInStatus() async {
    return await SharedPrefs.getData(userLoggedInKey, bool);
  }

  static Future<String?> getUserEmailFromSF() async {
    return await SharedPrefs.getData(userEmailKey, String);
  }

  static Future<String?> getUserNameFromSF() async {
    return await SharedPrefs.getData(userNameKey, String);
  }
}
