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