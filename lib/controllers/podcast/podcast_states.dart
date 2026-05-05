abstract class PodcastStates {}

class PodcastInitial extends PodcastStates {}

class PodcastLoading extends PodcastStates {}

class PodcastLoaded extends PodcastStates {
  final String playlistId;
  final List episodes;
  PodcastLoaded({required this.playlistId, required this.episodes});
}

class PodcastError extends PodcastStates {
  final String message;
  PodcastError(this.message);
}

class PodcastFilterState extends PodcastStates {}

class GetPodcastsLoadingStates extends PodcastStates{}
class GetPodcastsSuccessStates extends PodcastStates{}
class GetPodcastsErrorStates extends PodcastStates{
  final String error;
  GetPodcastsErrorStates(this.error);
}

class SuggestPodcastLoadingState extends PodcastStates{}
class SuggestPodcastSuccessState extends PodcastStates{}
class SuggestPodcastErrorState extends PodcastStates{}


