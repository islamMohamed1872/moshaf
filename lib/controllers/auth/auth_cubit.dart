import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:moshaf/controllers/auth/auth_states.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../network/firebase_errors_helper.dart';

extension on String {
  String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}


class AuthCubit extends Cubit<AuthStates>{
  AuthCubit() :super(AuthInitialState());
  static AuthCubit get(context) => BlocProvider.of(context);
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  var confirmPasswordController = TextEditingController();
  bool isPasswordHidden = true;
  void togglePasswordVisibility() {
    isPasswordHidden = !isPasswordHidden;
    emit(AuthChangePasswordVisibilityState());
  }

  void loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    emit(AuthLoginWithEmailAndPasswordLoadingState());

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      emit(AuthLoginWithEmailAndPasswordSuccessState());
    }  catch (error) {
      String message = "حدث خطأ غير متوقع. حاول مرة أخرى لاحقًا.";

      if (error is FirebaseAuthException) {
        message = firebaseAuthErrorMessage(error.code, fallback: error.message);
        print("FirebaseAuthException.code = ${error.code}");
        print("FirebaseAuthException.message = ${error.message}");
      } else if (error is PlatformException) {
        message = error.message ?? message;
      } else {
        final s = error.toString();
        if (s.isNotEmpty) message = s;
      }

      emit(AuthLoginWithEmailAndPasswordErrorState(message));
    }
  }


  void registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    emit(RegisterWithEmailAndPasswordLoadingState());

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      FirebaseAuth.instance.currentUser!.updateDisplayName(email);
      emit(RegisterWithEmailAndPasswordSuccessState());
    }  catch (error) {
      String message = "حدث خطأ غير متوقع. حاول مرة أخرى لاحقًا.";

      if (error is FirebaseAuthException) {
        message = firebaseAuthErrorMessage(error.code, fallback: error.message);
        print("FirebaseAuthException.code = ${error.code}");
        print("FirebaseAuthException.message = ${error.message}");
      } else if (error is PlatformException) {
        message = error.message ?? message;
      } else {
        final s = error.toString();
        if (s.isNotEmpty) message = s;
      }

      emit(RegisterWithEmailAndPasswordErrorState(message));
    }
  }
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signInWithGoogle() async {
    emit(AuthSignInWithGoogleLoadingState());

    try {
      final googleSignIn = GoogleSignIn.instance;

      // Initialize with web client ID for Android:
      await googleSignIn.initialize(
        serverClientId: '733056371061-b6gieovfqeh44d1qeac4962hkrcqk309.apps.googleusercontent.com',
      );

      // Interactive sign-in:
      final account = await googleSignIn.authenticate();

      if (account == null) {
        emit(AuthSignInWithGoogleErrorState("تم إلغاء تسجيل الدخول."));
        return;
      }

      // Authentication object:
      final auth = await account.authentication;

      // Build Firebase credential:
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        // accessToken: auth.accessToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      emit(AuthSignInWithGoogleSuccessState());
    } on GoogleSignInException catch (e) {
      debugPrint("GoogleSignInException.code = ${e.code}, desc = ${e.description}");
      emit(AuthSignInWithGoogleErrorState("خطأ تسجيل الدخول عبر Google"));
    } on FirebaseAuthException catch (e) {
      final msg = firebaseAuthErrorMessage(e.code, fallback: e.message);
      emit(AuthSignInWithGoogleErrorState(msg));
    } catch (e) {
      debugPrint("Unexpected Google sign-in error: $e");
      emit(AuthSignInWithGoogleErrorState("حدث خطأ غير متوقع. حاول مرة أخرى لاحقًا."));
    }
  }


  Future<UserCredential?> signInWithApple() async {
    emit(AuthSignInWithAppleLoadingState());

    try {
      // 🔹 Step 1: Generate secure nonce (for Firebase verification)
      final rawNonce = "".generateNonce();
      final nonce = "".sha256ofString(rawNonce);

      // 🔹 Step 2: Request Apple credentials
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // 🔹 Step 3: Firebase OAuth credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        // authorizationCode now optional but included for better validation
        accessToken: appleCredential.authorizationCode,
      );

      // 🔹 Step 4: Sign in to Firebase
      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      emit(AuthSignInWithAppleSuccessState());
      debugPrint("✅ Apple Sign-In successful: ${userCredential.user?.email}");
      return userCredential;
    }

    // 🔸 Handle Apple authorization flow errors
    on SignInWithAppleAuthorizationException catch (e) {
      String message;
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          message = "تم إلغاء عملية تسجيل الدخول عبر Apple.";
          break;
        case AuthorizationErrorCode.failed:
          message = "فشل تسجيل الدخول باستخدام Apple. حاول مرة أخرى.";
          break;
        case AuthorizationErrorCode.invalidResponse:
          message = "رد غير صالح من خوادم Apple. أعد المحاولة لاحقًا.";
          break;
        case AuthorizationErrorCode.notHandled:
          message = "لم يتم إكمال عملية تسجيل الدخول.";
          break;
        case AuthorizationErrorCode.unknown:
        default:
          message = "حدث خطأ غير متوقع أثناء تسجيل الدخول عبر Apple.";
          break;
      }

      debugPrint("🍎 Apple Sign-In Error: ${e.code} — ${e.message}");
      emit(AuthSignInWithAppleErrorState(message));
      return null;
    }

    // 🔸 Handle Firebase Authentication exceptions
    on FirebaseAuthException catch (e) {
      final message = firebaseAuthErrorMessage(e.code, fallback: e.message);
      debugPrint("🔥 FirebaseAuthException (Apple): ${e.code} — ${e.message}");
      emit(AuthSignInWithAppleErrorState(message));
      return null;
    }

    // 🔸 Handle unknown/unexpected errors
    catch (e) {
      debugPrint("❌ Unknown Apple Sign-In error: $e");
      emit(AuthSignInWithAppleErrorState("حدث خطأ أثناء تسجيل الدخول. حاول مرة أخرى."));
      return null;
    }
  }

  void clearControllers(){
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
  }

}