
import '../../models/playlist_model.dart';

abstract class PlaylistState {}

class PlaylistInitial extends PlaylistState {}

class PlaylistLoading extends PlaylistState {}

class PlaylistLoaded extends PlaylistState {
  final List<Playlist> playlists;
  PlaylistLoaded(this.playlists);
}

class PlaylistCreated extends PlaylistState {
  final Playlist playlist;
  PlaylistCreated(this.playlist);
}

class PlaylistSelected extends PlaylistState {
  final Playlist playlist;
  PlaylistSelected(this.playlist);
}

class ItemAddedToPlaylist extends PlaylistState {
  final PlaylistItem item;
  ItemAddedToPlaylist(this.item);
}

class ItemRemovedFromPlaylist extends PlaylistState {}

class PlaylistDeleted extends PlaylistState {}

class PlaylistError extends PlaylistState {
  final String message;
  PlaylistError(this.message);
}