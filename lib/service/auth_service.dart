import 'package:chatgrp_firebase/helper/helper_function.dart';
import 'package:chatgrp_firebase/service/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // login
  Future loginWithUserNameAndPassword(String email, String password) async {
    try {
      (await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ))
          .user!;
      return true;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // register with email and password
  Future registerUserWithEmailAndPassword(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      final User user = (await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ))
          .user!;
      await DatabaseService(uid: user.uid).updateUserData(fullName, email);
      return true;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // signout
  Future signOut() async {
    try {
      await HelperFunction.saverUserLoggedInStatus(false);
      await HelperFunction.saverUserEmailSF('');
      await HelperFunction.saverUserNameSF('');
      await firebaseAuth.signOut();
    } catch (e) {
      return null;
    }
  }

  // reset the password
  Future resetPassword({required String email}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else {
        return 'An error occurred while resetting password. Please try again later.';
      }
    } catch (e) {
      return 'An error occurred while resetting password. Please try again later.';
    }
  }

  // register with google
  Future registerWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();
      final GoogleSignInAuthentication? googleSignInAuthentication =
          await googleSignInAccount?.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication?.accessToken,
        idToken: googleSignInAuthentication?.idToken,
      );
      final User? user =
          (await firebaseAuth.signInWithCredential(credential)).user;
      if (user != null) {
        // check if user already exists in database
        final DocumentSnapshot userDoc =
            await _firebaseFirestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          // user doesn't exists, create new user
          final GoogleSignInAccount? currentUser =
              await _googleSignIn.signInSilently();
          // call our database service to update the user data
          DatabaseService(uid: user.uid)
              .updateUserData(user.displayName ?? 'User', user.email!);

          // fetch the google photo url
          final String? photoUrl = currentUser?.photoUrl;
          DatabaseService(uid: user.uid).userProfileUpdate(photoUrl!);
        }
        // saving the shared prefernce state
        await HelperFunction.saverUserLoggedInStatus(true);
        await HelperFunction.saverUserEmailSF(user.email!);
        await HelperFunction.saverUserNameSF(user.displayName!);
        return true;
      }
    } catch (e) {
      return 'Error in Registering with Google. Try Again';
    }
  }

  // get the user authentication provider
  Future<String?> authenticationProvider() async {
    final User? user = firebaseAuth.currentUser;
    if (user != null) {
      if (user.providerData.any(
        (element) => element.providerId == GoogleAuthProvider.PROVIDER_ID,
      )) {
        return 'Google';
      } else if (user.providerData.any(
        (element) => element.providerId == EmailAuthProvider.PROVIDER_ID,
      )) {
        return 'Email';
      }
    }
    return null;
  }
}
