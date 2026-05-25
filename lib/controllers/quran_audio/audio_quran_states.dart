abstract class AudioQuranStates{}

class AudioQuranInitialState extends AudioQuranStates{}
class PlayerStateChangedState extends AudioQuranStates{}
class SearchedSorahNumber extends AudioQuranStates{}
class IncreaseHomeCountSuccessState extends AudioQuranStates{}
class GetDataLoadingState extends AudioQuranStates{}
class ChangeSorahDuration extends AudioQuranStates{}
class GetPositionState extends AudioQuranStates{}
class SeekToState extends AudioQuranStates{}
class GetDataSuccessState extends AudioQuranStates{}
class AudioBufferingState extends AudioQuranStates{}
class GetDataErrorState extends AudioQuranStates{}
class ChangeSelectedShiekhState extends AudioQuranStates{}
class NextSurahState extends AudioQuranStates{}
class PrevSurahState extends AudioQuranStates{}
class AudioQuranStoppedState extends AudioQuranStates{}
class CurrentAyahChangedState extends AudioQuranStates {
  final String verseKey;
  CurrentAyahChangedState(this.verseKey);
}
class PlaylistPlayingState extends AudioQuranStates {
  final String playlistName;
  PlaylistPlayingState(this.playlistName);
}

class PlaylistFinishedState extends AudioQuranStates {}
class RepeatToggledState extends AudioQuranStates {}
class SetRepeatRangeState extends AudioQuranStates {}
