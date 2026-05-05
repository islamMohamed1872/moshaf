// ============================================================
// FILE 2: lib/controllers/hadith/hadith_states.dart
// ============================================================

abstract class HadithStates {}

class HadithInitialState       extends HadithStates {}
class HadithLoadingState       extends HadithStates {}
class HadithLoadedState        extends HadithStates {}
class HadithErrorState         extends HadithStates {
  final String message;
  HadithErrorState(this.message);
}
class HadithBookChangedState   extends HadithStates {}
class HadithPageChangedState   extends HadithStates {}
