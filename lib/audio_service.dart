import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
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
        playNextSong();
      }
    });

    _initializeQueue();
  }

  Future<void> _initializeQueue() async {
    try {
      String jsonString = await rootBundle.loadString('assets/canciones.json');
      List<dynamic> jsonList = json.decode(jsonString);

      _queue = jsonList.map((item) => item as Map<String, dynamic>).toList();

      if (_isShuffleMode) {
        _queue.shuffle();
      }
      if (_queue.isNotEmpty) {
        playSong(_queue.first['ruta'], _queue.first['titulo']);
      }
    } catch (e) {
      print('Error loading songs: $e');
    }
  }

  Future<void> playSong(String url, String title) async {
    try {
      _currentSong = title;
      _isPlaying = false;
      notifyListeners();

      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(url)));
      await _audioPlayer.play();

      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      print('Error playing song: $e');
      _currentSong = '';
      _isPlaying = false;
      notifyListeners();
    }
  }

  void playNextSong() {
    if (_queue.isEmpty) return;

    int currentIndex = _queue.indexWhere((song) => song['titulo'] == _currentSong);
    int nextIndex;

    if (_isShuffleMode) {
      nextIndex = _random.nextInt(_queue.length);
    } else {
      nextIndex = (currentIndex + 1) % _queue.length;
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