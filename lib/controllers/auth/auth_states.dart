abstract class AuthStates{}

class AuthInitialState extends AuthStates{}
class AuthChangePasswordVisibilityState extends AuthStates{}

class AuthLoginWithEmailAndPasswordLoadingState extends AuthStates{}
class AuthLoginWithEmailAndPasswordSuccessState extends AuthStates{}
class AuthLoginWithEmailAndPasswordErrorState extends AuthStates{
  final String errorMessage;
  AuthLoginWithEmailAndPasswordErrorState(this.errorMessage);
}

class RegisterWithEmailAndPasswordLoadingState extends AuthStates{}
class RegisterWithEmailAndPasswordSuccessState extends AuthStates{}
class RegisterWithEmailAndPasswordErrorState extends AuthStates{
  final String errorMessage;
  RegisterWithEmailAndPasswordErrorState(this.errorMessage);
}

class AuthSignInWithGoogleLoadingState extends AuthStates {}

class AuthSignInWithGoogleSuccessState extends AuthStates {}

class AuthSignInWithGoogleErrorState extends AuthStates {
  final String error;
  AuthSignInWithGoogleErrorState(this.error);
}

class AuthSignInWithAppleLoadingState extends AuthStates {}
class AuthSignInWithAppleSuccessState extends AuthStates {}
class AuthSignInWithAppleErrorState extends AuthStates {
  final String error;
  AuthSignInWithAppleErrorState(this.error);
}