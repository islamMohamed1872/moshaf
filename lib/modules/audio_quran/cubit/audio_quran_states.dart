abstract class AudioQuranStates{}

class AudioQuranInitialState extends AudioQuranStates{}
class SearchedSorahNumber extends AudioQuranStates{}
class IncreaseHomeCountSuccessState extends AudioQuranStates{}
class GetDataLoadingState extends AudioQuranStates{}
class ChangeSorahDuration extends AudioQuranStates{}
class GetPositionState extends AudioQuranStates{}
class GetDataSuccessState extends AudioQuranStates{}
class GetDataErrorState extends AudioQuranStates{}
class ChangeSelectedShiekhState extends AudioQuranStates{}
class NextSurahState extends AudioQuranStates{}
class PrevSurahState extends AudioQuranStates{}
class CurrentAyahChangedState extends AudioQuranStates {
  final String verseKey;
  CurrentAyahChangedState(this.verseKey);
}
