String firebaseAuthErrorMessage(String code, {String? fallback}) {
  switch (code) {
  // 🟢 Email/password
    case 'invalid-email':
      return "يرجى إدخال بريد إلكتروني صالح.";
    case 'user-disabled':
      return "تم إيقاف هذا الحساب مؤقتًا.";
    case 'user-not-found':
      return "لم يتم العثور على حساب بهذا البريد الإلكتروني.";
    case 'wrong-password':
      return "كلمة المرور غير صحيحة. حاول مرة أخرى.";
    case 'email-already-in-use':
      return "هذا البريد الإلكتروني مستخدم بالفعل.";
    case 'weak-password':
      return "كلمة المرور ضعيفة جدًا.";
    case 'operation-not-allowed':
      return "تسجيل الدخول بهذه الطريقة غير مفعّل حاليًا.";
    case 'too-many-requests':
      return "محاولات كثيرة. يرجى المحاولة لاحقًا.";
    case 'network-request-failed':
      return "لا يوجد اتصال بالإنترنت.";

  // 🔵 Credential/Session
    case 'invalid-credential':
      return "بيانات تسجيل الدخول غير صالحة أو انتهت صلاحيتها.";
    case 'requires-recent-login':
      return "يرجى تسجيل الدخول مجددًا لتأكيد هويتك.";
    case 'user-mismatch':
      return "بيانات المستخدم لا تتطابق مع الحساب الحالي.";
    case 'account-exists-with-different-credential':
      return "هذا البريد مسجّل بطريقة مختلفة. استخدم نفس طريقة التسجيل السابقة.";
    case 'provider-already-linked':
      return "طريقة تسجيل الدخول هذه مفعّلة بالفعل.";
    case 'invalid-verification-code':
      return "رمز التحقق غير صحيح أو انتهت صلاحيته.";
    case 'invalid-verification-id':
      return "رمز التحقق غير صالح.";
    case 'expired-action-code':
      return "انتهت صلاحية الرابط. اطلب رابطًا جديدًا.";

  // 🔴 Google Sign-In
    case 'sign_in_canceled':
    case 'GoogleSignInExceptionCode.canceled':
      return "تم إلغاء تسجيل الدخول باستخدام Google.";
    case 'sign_in_failed':
    case 'GoogleSignInExceptionCode.failed':
      return "فشل تسجيل الدخول باستخدام Google.";
    case 'network_error':
    case 'GoogleSignInExceptionCode.networkError':
      return "تحقق من اتصالك بالإنترنت.";
    case 'popup-closed-by-user':
      return "تم إغلاق نافذة تسجيل الدخول.";
    case 'already-in-progress':
      return "عملية تسجيل دخول أخرى قيد التنفيذ.";
    case 'unknown':
    case 'GoogleSignInExceptionCode.unknown':
      return "حدث خطأ غير متوقع أثناء تسجيل الدخول.";

  // 🍎 Apple Sign-In
    case 'SignInWithAppleAuthorizationException.canceled':
      return "تم إلغاء تسجيل الدخول عبر Apple.";
    case 'SignInWithAppleAuthorizationException.failed':
      return "فشل تسجيل الدخول باستخدام Apple.";
    case 'SignInWithAppleAuthorizationException.invalidResponse':
      return "رد غير صالح من Apple.";
    case 'SignInWithAppleAuthorizationException.notHandled':
      return "لم يتم إكمال تسجيل الدخول.";
    case 'SignInWithAppleAuthorizationException.unknown':
      return "حدث خطأ غير متوقع أثناء تسجيل الدخول عبر Apple.";
    case 'apple-missing-auth':
      return "لم يتم استلام بيانات تسجيل الدخول من Apple.";
    case 'apple-invalid-credential':
      return "رمز تسجيل الدخول من Apple غير صالح. أعد المحاولة.";
    case 'apple-operation-not-allowed':
      return "تسجيل الدخول عبر Apple غير مفعّل في Firebase.";

  // ⚫ OAuth general
    case 'unauthorized-domain':
      return "المجال غير مصرح به لتسجيل الدخول.";
    case 'id-token-expired':
      return "انتهت صلاحية الجلسة. أعد تسجيل الدخول.";
    case 'invalid-oauth-client-id':
      return "حدث خطأ في إعداد تطبيق OAuth.";

  // 🟣 Default
    default:
      if (fallback != null && fallback.isNotEmpty) {
        return fallback;
      }
      return "حدث خطأ غير متوقع. يرجى المحاولة لاحقًا.";
  }
}
