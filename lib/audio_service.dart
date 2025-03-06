import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class AudioService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _currentSong = '';
  bool _isPlaying = false;

  String get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;

  AudioService() {
    _audioPlayer.playerStateStream.listen((playerState) {
      _isPlaying = playerState.playing;
      notifyListeners();
    });
  }

  Future<void> playSong(String url, String title) async {
    try {
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
      _currentSong = title;
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      print('Error playing song: $e');
      _currentSong = '';
      _isPlaying = false;
      notifyListeners();
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}