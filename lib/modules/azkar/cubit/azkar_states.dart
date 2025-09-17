abstract class AzkarStates {}

class AzkarInitialState extends AzkarStates {}
class AzkarLoadingState extends AzkarStates {}
class AzkarLoadedState extends AzkarStates {}
class AzkarErrorState extends AzkarStates {
  final String message;
  AzkarErrorState(this.message);
}
class AzkarPlayChangedState extends AzkarStates {}
