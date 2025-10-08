import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static String userIdkey = "USERKEY";
  static String userNamekey = "USERNAMEKEY";
  static String userEmailkey = "USERMAILKEY";
  static String userImagekey = "USERIMAGEKEY";

  Future<bool> saveUserId(String getUserID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userIdkey, getUserID);
  }

  Future<bool> saveNameId(String getUserName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userNamekey, getUserName);
  }

  Future<bool> saveUserEmail(String getUserEmail) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userEmailkey, getUserEmail);
  }

  Future<bool> saveUserImage(String getUserImage) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userImagekey, getUserImage);
  }


  Future<String?> getUserID()async{
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(userIdkey);
  }

  Future<String?> getUserName()async{
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(userNamekey);
  }

  Future<String?> getUserEmail()async{
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(userEmailkey);
  }

  Future<String?> getUserImage()async{
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(userImagekey);
  }


}
