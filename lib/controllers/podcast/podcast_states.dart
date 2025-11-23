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
