abstract class TextQuranStates{}

class TextQuranInitialState extends TextQuranStates{}
class SearchedSorahNumber extends TextQuranStates{}
class NextPageSuccessState extends TextQuranStates{}
class PreviousPageSuccessState extends TextQuranStates{}
class IncreaseHomeCountSuccessState extends TextQuranStates{}
class GetLastReadState extends TextQuranStates{}
class GetSharedPreferencesLoadingState extends TextQuranStates{}
class GetSharedPreferencesSuccessState extends TextQuranStates{}
class GetSharedPreferencesEmptyState extends TextQuranStates{}
class LoadJsonAssetState extends TextQuranStates{}
class AddFilteredDataState extends TextQuranStates{}
class ChangeSearchQueryState extends TextQuranStates{}
class ChangeFilteredDataState extends TextQuranStates{}
class SearchForDataState extends TextQuranStates{}
class SetIndexState extends TextQuranStates{}
class ChangePageState extends TextQuranStates{}
class SetSelectedVerseState extends TextQuranStates{}
class GetFontLoadingState extends TextQuranStates{}
class TextQuranCacheChecked extends TextQuranStates{}
class GetFontSuccessState extends TextQuranStates{}
class GetFontErrorState extends TextQuranStates{}
class GetVerseTafseerLoadingState extends TextQuranStates{}
class GetVerseTafseerSuccessState extends TextQuranStates{}
class GetVerseTafseerErrorState extends TextQuranStates{}
class GetPlaceOfRevelationState extends TextQuranStates{}
class TextQuranLoadingState extends TextQuranStates {}

class TextQuranPlayingState extends TextQuranStates {}

class TextQuranPausedState extends TextQuranStates {}

class TextQuranStoppedState extends TextQuranStates {}
class ChangeFilterState extends TextQuranStates {}

class TextQuranVerseChangedState extends TextQuranStates {
  final String verseText;
  TextQuranVerseChangedState(this.verseText);
}

class TextQuranErrorState extends TextQuranStates {
  final String error;
  TextQuranErrorState(this.error);
}