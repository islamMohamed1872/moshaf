abstract class HomeStates{}

class HomeInitialState extends HomeStates{}

class IsFirstTimeState extends HomeStates{}
class GetRandomAthkarState extends HomeStates{}
class GetNewRandomAthkarState extends HomeStates{}
class HomeTutorialStarted extends HomeStates{}
class HomeTutorialStepChanged extends HomeStates{}
class HomeTutorialFinished extends HomeStates{}
class HomeTutorialStepRequested extends HomeStates {
  final int index;
  HomeTutorialStepRequested(this.index);
}

class ZekrLoadingState extends HomeStates {}
class ZekrLoadedState extends HomeStates {}

class AllahNameLoadingState extends HomeStates {}
class AllahNameLoadedState   extends HomeStates {}
class RafeqVisibilityChanged extends HomeStates {}

class DailyAyahLoadingState extends HomeStates {}

class DailyAyahLoadedState extends HomeStates {}

class DailyHadithLoadingState extends HomeStates {}

class DailyHadithLoadedState extends HomeStates {}