import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:async';

class AudioService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Map<String, dynamic>? _currentSong;
  bool _isPlaying = false;
  bool _isShuffleMode = false;
  bool _isRepeatMode = false;
  List<Map<String, dynamic>> _queue = [];
  int _currentIndex = -1;

  // Estados de error y conectividad
  bool _hasError = false;
  String? _errorMessage;
  bool _isBuffering = false;

  // Getters
  bool get isShuffleMode => _isShuffleMode;
  bool get isRepeatMode => _isRepeatMode;
  Map<String, dynamic>? get currentSong => _currentSong;
  String get currentSongTitle => _currentSong?['titulo'] ?? '';
  String get currentArtist => _currentSong?['artista'] ?? '';
  String get currentImage => _currentSong?['imagen'] ?? '';
  bool get isPlaying => _isPlaying;
  List<Map<String, dynamic>> get queue => List.unmodifiable(_queue);
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get isBuffering => _isBuffering;
  int get currentIndex => _currentIndex;
  int get queueLength => _queue.length;

  AudioService() {
    _setupAudioPlayer();
    _queue = [];
  }

  void _setupAudioPlayer() {
    // Listener para cambios de estado del reproductor
    _audioPlayer.playerStateStream.listen((playerState) {
      _isPlaying = playerState.playing;
      _isBuffering = playerState.processingState == ProcessingState.buffering;

      _hasError = playerState.processingState == ProcessingState.idle &&
          playerState.playing == false &&
          _currentSong != null;

      notifyListeners();

      // Cuando la canción termina
      if (playerState.processingState == ProcessingState.completed) {
        if (_isRepeatMode && _currentSong != null) {
          // Repetir la misma canción
          _playCurrentSongAgain();
        } else {
          // Reproducir siguiente canción
          playNextSong();
        }
      }
    });

    // Listener para eventos de reproducción
    _audioPlayer.playbackEventStream.listen((playbackEvent) {
      if (playbackEvent.processingState == ProcessingState.completed) {
        if (_isRepeatMode && _currentSong != null) {
          _playCurrentSongAgain();
        } else {
          playNextSong();
        }
      }
    }, onError: (e) {
      print('Playback error: $e');
      _errorMessage = 'Error de reproducción';
      _hasError = true;
      notifyListeners();
    });

    // Listener para buffering
    _audioPlayer.bufferedPositionStream.listen((position) {
      // Puedes usar esto para mostrar progreso de buffering
    });
  }

  // Método para preparar canción de Deezer API
  Map<String, dynamic> _prepareDeezerSong(Map<String, dynamic> deezerSong) {
    return {
      'titulo': deezerSong['title']?.toString() ?? 'Título desconocido',
      'artista': deezerSong['artist']?['name']?.toString() ?? 'Artista desconocido',
      'preview': deezerSong['preview']?.toString() ?? '',
      'album': deezerSong['album']?['title']?.toString() ?? 'Álbum desconocido',
      'imagen': deezerSong['album']?['cover_medium']?.toString() ??
          'https://e-cdns-images.dzcdn.net/images/cover/250x250-000000-80-0-0.jpg',
      'id': deezerSong['id']?.toString() ?? UniqueKey().toString(),
      'duration': deezerSong['duration'] ?? 0,
      'originalData': deezerSong,
    };
  }

  Future<void> playSongFromMap(Map<String, dynamic> song) async {
    try {
      _hasError = false;
      _errorMessage = null;
      _isBuffering = true;

      // Preparar la canción si viene de Deezer API
      final preparedSong = song.containsKey('title')
          ? _prepareDeezerSong(song)
          : song;

      _currentSong = preparedSong;

      // Buscar índice en la cola
      _currentIndex = _queue.indexWhere((s) =>
      s['id'] == preparedSong['id'] ||
          s['titulo'] == preparedSong['titulo']);

      if (_currentIndex == -1) {
        // Si no está en la cola, añadirla
        _queue.add(preparedSong);
        _currentIndex = _queue.length - 1;
      }

      notifyListeners();

      final url = preparedSong['preview']?.toString() ?? '';
      if (url.isEmpty) {
        throw Exception('URL de audio no disponible para "${preparedSong['titulo']}"');
      }

      // Detener reproducción actual
      await _audioPlayer.stop();

      // Configurar nueva fuente de audio
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: preparedSong,
        ),
      );

      // Reproducir con manejo de errores
      await _audioPlayer.play().catchError((e) {
        print('Play error: $e');
        _errorMessage = 'No se pudo reproducir "${preparedSong['titulo']}"';
        _hasError = true;
        _isPlaying = false;
        _isBuffering = false;
        notifyListeners();
        throw e;
      });

      _isPlaying = true;
      _isBuffering = false;
      notifyListeners();

      print('🎵 Reproduciendo: ${preparedSong['titulo']} - ${preparedSong['artista']}');
    } catch (e) {
      print('Error playing song: $e');
      _errorMessage = 'Error: ${e.toString()}';
      _hasError = true;
      _currentSong = null;
      _isPlaying = false;
      _isBuffering = false;
      notifyListeners();
    }
  }

  void _playCurrentSongAgain() {
    if (_currentSong != null && _currentIndex >= 0 && _currentIndex < _queue.length) {
      // Buscar la canción actual en la cola por si ha cambiado
      final currentSongId = _currentSong!['id'];
      final index = _queue.indexWhere((song) => song['id'] == currentSongId);

      if (index != -1) {
        _currentIndex = index;
        playSongFromMap(_queue[index]);
      }
    }
  }

  void playNextSong() {
    if (_queue.isEmpty) return;

    if (_isShuffleMode) {
      // En modo shuffle, evitar reproducir la misma canción consecutivamente
      int newIndex;
      do {
        newIndex = Random().nextInt(_queue.length);
      } while (newIndex == _currentIndex && _queue.length > 1);

      _currentIndex = newIndex;
    } else {
      _currentIndex = (_currentIndex + 1) % _queue.length;
    }

    if (_currentIndex < _queue.length) {
      playSongFromMap(_queue[_currentIndex]);
    }
  }

  void playPreviousSong() {
    if (_queue.isEmpty) return;

    if (_isPlaying && _audioPlayer.position.inSeconds > 3) {
      // Si estamos en los primeros 3 segundos, ir a canción anterior
      // Si no, reiniciar la canción actual
      seek(Duration.zero);
      return;
    }

    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;

    if (_currentIndex < _queue.length) {
      playSongFromMap(_queue[_currentIndex]);
    }
  }

  Future<void> pauseSong() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      print('Pause error: $e');
    }
  }

  Future<void> resumeSong() async {
    try {
      await _audioPlayer.play();
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      print('Resume error: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      notifyListeners();
    } catch (e) {
      print('Seek error: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
      notifyListeners();
    } catch (e) {
      print('Volume error: $e');
    }
  }

  void toggleShuffleMode() {
    _isShuffleMode = !_isShuffleMode;
    notifyListeners();
  }

  void toggleRepeatMode() {
    _isRepeatMode = !_isRepeatMode;
    notifyListeners();
  }

  void addToQueue(Map<String, dynamic> song) {
    // Preparar la canción si viene de Deezer API
    final preparedSong = song.containsKey('title')
        ? _prepareDeezerSong(song)
        : song;

    _queue.add(preparedSong);
    notifyListeners();
  }

  void addMultipleToQueue(List<Map<String, dynamic>> songs) {
    for (var song in songs) {
      addToQueue(song);
    }
  }

  void insertNextInQueue(Map<String, dynamic> song) {
    // Preparar la canción si viene de Deezer API
    final preparedSong = song.containsKey('title')
        ? _prepareDeezerSong(song)
        : song;

    if (_currentIndex >= 0 && _currentIndex < _queue.length - 1) {
      _queue.insert(_currentIndex + 1, preparedSong);
    } else {
      _queue.add(preparedSong);
    }
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      // Si estamos eliminando la canción actual
      if (index == _currentIndex) {
        _audioPlayer.stop();
        _currentSong = null;
        _isPlaying = false;
        _currentIndex = -1;
      }

      _queue.removeAt(index);

      // Ajustar índice actual si es necesario
      if (_currentIndex > index) {
        _currentIndex--;
      }

      notifyListeners();
    }
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _queue.length ||
        newIndex < 0 ||
        newIndex >= _queue.length ||
        oldIndex == newIndex) {
      return;
    }

    final song = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, song);

    // Actualizar índice actual si fue movido
    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (_currentIndex > oldIndex && _currentIndex <= newIndex) {
      _currentIndex--;
    } else if (_currentIndex < oldIndex && _currentIndex >= newIndex) {
      _currentIndex++;
    }

    notifyListeners();
  }

  // Métodos auxiliares

  void clearQueue() {
    _audioPlayer.stop();
    _queue.clear();
    _currentSong = null;
    _currentIndex = -1;
    _isPlaying = false;
    _hasError = false;
    _errorMessage = null;
    _isBuffering = false;
    notifyListeners();
  }

  void clearErrors() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  void moveToTop(int index) {
    if (index > 0 && index < _queue.length) {
      final song = _queue.removeAt(index);
      _queue.insert(0, song);

      // Actualizar índice actual
      if (_currentIndex == index) {
        _currentIndex = 0;
      } else if (_currentIndex < index) {
        _currentIndex++;
      }

      notifyListeners();
    }
  }

  void moveToBottom(int index) {
    if (index >= 0 && index < _queue.length - 1) {
      final song = _queue.removeAt(index);
      _queue.add(song);

      // Actualizar índice actual
      if (_currentIndex == index) {
        _currentIndex = _queue.length - 1;
      } else if (_currentIndex > index) {
        _currentIndex--;
      }

      notifyListeners();
    }
  }

  void playSongAtIndex(int index) {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      playSongFromMap(_queue[index]);
    }
  }

  List<Map<String, dynamic>> get upcomingSongs {
    if (_queue.isEmpty || _currentIndex == -1) {
      return [];
    }

    if (_isShuffleMode) {
      // En modo shuffle, devolver todas menos la actual
      return List.from(_queue)..removeAt(_currentIndex);
    }

    // En modo normal, devolver canciones después de la posición actual
    final startIndex = _currentIndex + 1;
    if (startIndex >= _queue.length) {
      return [];
    }

    return _queue.sublist(startIndex);
  }

  List<Map<String, dynamic>> get previousSongs {
    if (_queue.isEmpty || _currentIndex <= 0) {
      return [];
    }

    return _queue.sublist(0, _currentIndex);
  }

  bool get hasNextSong {
    if (_queue.isEmpty) return false;
    if (_isShuffleMode) return _queue.length > 1;
    return _currentIndex < _queue.length - 1;
  }

  bool get hasPreviousSong {
    if (_queue.isEmpty) return false;
    return _currentIndex > 0;
  }

  bool get isFirstSong {
    return _currentIndex == 0;
  }

  bool get isLastSong {
    return _currentIndex == _queue.length - 1;
  }

  // Getters para el reproductor
  Duration? get currentPosition => _audioPlayer.position;
  Duration? get totalDuration => _audioPlayer.duration;
  double get volume => _audioPlayer.volume;
  double? get speed => _audioPlayer.speed;

  // Streams para UI
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<double> get volumeStream => _audioPlayer.volumeStream;
  Stream<double?> get speedStream => _audioPlayer.speedStream;

  // Método para cambiar velocidad de reproducción
  Future<void> setSpeed(double speed) async {
    try {
      await _audioPlayer.setSpeed(speed.clamp(0.5, 2.0));
      notifyListeners();
    } catch (e) {
      print('Speed error: $e');
    }
  }

  // Método para verificar si una canción es la actual
  bool isCurrentSong(Map<String, dynamic> song) {
    if (_currentSong == null) return false;
    final songId = song['id']?.toString();
    final currentSongId = _currentSong!['id']?.toString();
    return songId == currentSongId;
  }

  // Método para obtener el índice de una canción en la cola
  int getSongIndex(Map<String, dynamic> song) {
    final songId = song['id']?.toString();
    return _queue.indexWhere((s) => s['id']?.toString() == songId);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}