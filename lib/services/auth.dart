import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';

class AuthMethod {
  final FirebaseAuth _auth = FirebaseAuth.instance;

 Future SignOut()async {
  await FirebaseAuth.instance.signOut();
 }
  Future deleteUser()async {
    User? user = await FirebaseAuth.instance.currentUser;
    user?.delete();
  }
}

