
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:io';


abstract class BaseAuth {
  Future<String> signInWithEmail(String email, String password);

  Future<String> signUpWithEmail(String email, String password);

  Future<FirebaseUser> getCurrentUser();

  Future<String> ensureLogedIn();

  Future<bool> isLogedIn();

  Future<void> signOut();
}

class Auth implements BaseAuth {

  final FirebaseAuth _auth = FirebaseAuth.instance;


  @override
  Future<FirebaseUser> getCurrentUser() async {
    FirebaseUser user = await _auth.currentUser();
    return user;
  }

  @override
  Future<String> signInWithEmail(String email, String password) async {
    FirebaseUser user = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    if(user != null && user.isAnonymous == false) {
      return user.uid;
    }
    return null;
  }

  @override
  Future<String> signUpWithEmail(String email, String password) async {
    FirebaseUser user = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    if(user != null && user.isAnonymous == false) {
      return user.uid;
    }
    return null;
  }



  @override
  Future<String> ensureLogedIn() async {
    FirebaseUser firebaseUser = await _auth.currentUser();
    assert(firebaseUser != null);
    assert(firebaseUser.isAnonymous == false);
    return firebaseUser.uid;
  }

  @override
  Future<bool> isLogedIn() async{
    FirebaseUser firebaseUser = await _auth.currentUser();
    if(firebaseUser != null && firebaseUser.isAnonymous == false){
      return true;
    }
    return false;
  }

  @override
  Future<void> signOut() {
    return _auth.signOut();
  }


}
