import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class AudioService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _currentSong = '';
  bool _isPlaying = false;
  bool _isShuffleMode = false;
  List<Map<String, dynamic>> _queue = [];
  final Random _random = Random();

  String get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  List<Map<String, dynamic>> get queue => _queue;

  AudioService() {
    _audioPlayer.playerStateStream.listen((playerState) {
      _isPlaying = playerState.playing;
      notifyListeners();

      if (playerState.processingState == ProcessingState.completed) {
        playNextSong(); // Ahora sigue reproduciendo automáticamente
      }
    });

    _initializeQueue();
  }

  void _initializeQueue() {
    if (_isShuffleMode) {
      _queue.shuffle();
    }
    if (_queue.isNotEmpty) {
      playSong(_queue.first['ruta'], _queue.first['titulo']);
    }
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

  void playNextSong() {
    if (_queue.isEmpty) return;

    int nextIndex;
    int currentIndex = _queue.indexWhere((song) => song['titulo'] == _currentSong);

    if (_isShuffleMode) {
      nextIndex = _random.nextInt(_queue.length);
    } else {
      nextIndex = (currentIndex + 1) % _queue.length; // Reproduce en orden y vuelve al inicio
    }

    playSong(_queue[nextIndex]['ruta'], _queue[nextIndex]['titulo']);
  }

  void playPreviousSong() {
    if (_queue.isEmpty) return;

    int currentIndex = _queue.indexWhere((song) => song['titulo'] == _currentSong);
    int previousIndex = (currentIndex - 1 + _queue.length) % _queue.length;

    playSong(_queue[previousIndex]['ruta'], _queue[previousIndex]['titulo']);
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

  void toggleShuffleMode() {
    _isShuffleMode = !_isShuffleMode;
    if (_isShuffleMode) {
      _queue.shuffle();
    }
    notifyListeners();
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
    if (oldIndex != newIndex) {
      final song = _queue.removeAt(oldIndex);
      _queue.insert(newIndex, song);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}