import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class AudioService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _currentSong = '';
  bool _isPlaying = false;
  bool _isLoopMode = false;
  bool _isSingleLoopMode = false;
  List<Map<String, dynamic>> _queue = [];

  String get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  List<Map<String, dynamic>> get queue => _queue;

  AudioService() {
    _audioPlayer.playerStateStream.listen((playerState) {
      _isPlaying = playerState.playing;
      notifyListeners();

      if (playerState.processingState == ProcessingState.completed) {
        playNextSong();
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (_isSingleLoopMode && position >= (_audioPlayer.duration ?? Duration.zero)) {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.play();
      }
    });
  }

  Future<void> playSong(String url, String title) async {
    try {
      _currentSong = title;
      _isPlaying = false;
      notifyListeners();

      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();

      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      print('Error al reproducir la canción: $e');
      _currentSong = '';
      _isPlaying = false;
      notifyListeners();
    }
  }

  void addToQueue(Map<String, dynamic> song) {
    _queue.add(song);
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      notifyListeners();
    }
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);
    notifyListeners();
  }

  Future<void> playNextSong() async {
    if (_queue.isNotEmpty) {
      final nextSong = _queue.removeAt(0);
      await playSong(nextSong['ruta'], nextSong['titulo']);
    } else {
      await stopSong();
    }
  }

  Future<void> playPreviousSong(List<Map<String, dynamic>> playlist) async {
    int currentIndex = playlist.indexWhere((song) => song['titulo'] == _currentSong);
    if (currentIndex != -1) {
      int previousIndex = (currentIndex - 1 + playlist.length) % playlist.length;
      await playSong(playlist[previousIndex]['ruta'], playlist[previousIndex]['titulo']);
    }
  }

  Future<void> pauseSong() async {
    await _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> resumeSong() async {
    await _audioPlayer.play();
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> stopSong() async {
    await _audioPlayer.stop();
    _currentSong = '';
    _isPlaying = false;
    notifyListeners();
  }

  void toggleLoopMode() {
    if (!_isLoopMode && !_isSingleLoopMode) {
      _isLoopMode = true;
      _audioPlayer.setLoopMode(LoopMode.all);
    } else if (_isLoopMode) {
      _isLoopMode = false;
      _isSingleLoopMode = true;
      _audioPlayer.setLoopMode(LoopMode.off);
    } else {
      _isSingleLoopMode = false;
      _audioPlayer.setLoopMode(LoopMode.off);
    }
    notifyListeners();
  }

  void toggleShuffleMode() {
    if (_audioPlayer.shuffleModeEnabled) {
      _audioPlayer.setShuffleModeEnabled(false);
    } else {
      _queue.shuffle();
      _audioPlayer.setShuffleModeEnabled(true);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}