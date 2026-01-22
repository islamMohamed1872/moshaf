import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moshaf/controllers/playlist/playlist_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moshaf/models/playlist_model.dart';


class PlaylistCubit extends Cubit<PlaylistState> {
  PlaylistCubit() : super(PlaylistInitial());

  static PlaylistCubit get(context) => BlocProvider.of(context);

  final String _storageKey = 'quran_playlists';
  List<Playlist> playlists = [];
  Playlist? currentPlaylist;

  Future<void> loadPlaylists() async {
    emit(PlaylistLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = prefs.getStringList(_storageKey) ?? [];

      playlists = playlistsJson
          .map((json) => Playlist.fromJson(jsonDecode(json)))
          .toList();

      emit(PlaylistLoaded(playlists));
    } catch (e) {
      emit(PlaylistError('Failed to load playlists: $e'));
    }
  }

  Future<void> createPlaylist(String name) async {
    try {
      final newPlaylist = Playlist(
        name: name,
        items: [],
      );

      playlists.add(newPlaylist);
      await _savePlaylists();

      emit(PlaylistCreated(newPlaylist));
      emit(PlaylistLoaded(playlists));
    } catch (e) {
      emit(PlaylistError('Failed to create playlist: $e'));
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      playlists.removeWhere((p) => p.id == playlistId);
      await _savePlaylists();

      emit(PlaylistDeleted());
      emit(PlaylistLoaded(playlists));
    } catch (e) {
      emit(PlaylistError('Failed to delete playlist: $e'));
    }
  }

  Future<void> addItemToPlaylist(
      String playlistId,
      int surah,
      int startVerse,
      int endVerse,
      ) async {
    try {
      final playlist = playlists.firstWhere((p) => p.id == playlistId);
      final item = PlaylistItem(
        surah: surah,
        startVerse: startVerse,
        endVerse: endVerse,
      );

      playlist.items.add(item);
      await _savePlaylists();

      emit(ItemAddedToPlaylist(item));
      emit(PlaylistLoaded(playlists));
    } catch (e) {
      emit(PlaylistError('Failed to add item: $e'));
    }
  }

  Future<void> removeItemFromPlaylist(String playlistId, int itemIndex) async {
    try {
      final playlist = playlists.firstWhere((p) => p.id == playlistId);
      playlist.items.removeAt(itemIndex);
      await _savePlaylists();

      emit(ItemRemovedFromPlaylist());
      emit(PlaylistLoaded(playlists));
    } catch (e) {
      emit(PlaylistError('Failed to remove item: $e'));
    }
  }

  void selectPlaylist(Playlist playlist) {
    currentPlaylist = playlist;
    emit(PlaylistSelected(playlist));
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = playlists
        .map((p) => jsonEncode(p.toJson()))
        .toList();

    await prefs.setStringList(_storageKey, playlistsJson);
  }
}