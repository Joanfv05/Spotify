import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../audio_service.dart';
import 'queue_screen.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistName;

  const PlaylistScreen({Key? key, required this.playlistName}) : super(key: key);

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<Map<String, dynamic>> _canciones = [];
  bool _isShuffleMode = false;
  bool _isLoopMode = false;
  bool _isSingleLoopMode = false;

  @override
  void initState() {
    super.initState();
    _cargarCanciones();
  }

  Future<void> _cargarCanciones() async {
    final String response = await rootBundle.loadString('assets/canciones.json');
    final data = await json.decode(response);
    setState(() {
      _canciones = List<Map<String, dynamic>>.from(data);
    });
  }

  void _toggleShuffleMode() {
    setState(() {
      _isShuffleMode = !_isShuffleMode;
      _isShuffleMode ? _canciones.shuffle() : _canciones.sort((a, b) => a['id'].compareTo(b['id']));
    });
  }

  void _toggleLoopMode() {
    setState(() {
      if (!_isLoopMode && !_isSingleLoopMode) {
        _isLoopMode = true;
      } else if (_isLoopMode) {
        _isLoopMode = false;
        _isSingleLoopMode = true;
      } else {
        _isSingleLoopMode = false;
      }
    });
  }

  void _showQueueOptions(BuildContext context, Map<String, dynamic> song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(  // Evita que el modal quede debajo de la barra de navegación
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.playlist_add),
                  title: Text('Añadir a la cola'),
                  onTap: () {
                    Provider.of<AudioService>(context, listen: false).addToQueue(song);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _playNextSong(AudioService audioService) {
    int currentIndex = _canciones.indexWhere((cancion) => cancion['titulo'] == audioService.currentSong);
    if (currentIndex != -1) {
      int nextIndex = (currentIndex + 1) % _canciones.length;
      audioService.playSong(_canciones[nextIndex]['ruta'], _canciones[nextIndex]['titulo']);
    }
  }

  void _playPreviousSong(AudioService audioService) {
    int currentIndex = _canciones.indexWhere((cancion) => cancion['titulo'] == audioService.currentSong);
    if (currentIndex != -1) {
      int previousIndex = (currentIndex - 1 + _canciones.length) % _canciones.length;
      audioService.playSong(_canciones[previousIndex]['ruta'], _canciones[previousIndex]['titulo']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audioService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.playlistName, style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red[900],
            actions: [
              IconButton(
                icon: Icon(Icons.queue_music),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => QueueScreen()));
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: ListView.builder(
                      itemCount: _canciones.length,
                      itemBuilder: (context, index) {
                        final cancion = _canciones[index];
                        return ListTile(
                          leading: Icon(Icons.music_note, color: Colors.red),
                          title: Text(cancion['titulo'], style: TextStyle(color: Colors.white)),
                          subtitle: Text(cancion['artista'], style: TextStyle(color: Colors.red[300])),
                          trailing: IconButton(
                            icon: Icon(Icons.more_vert, color: Colors.white),
                            onPressed: () => _showQueueOptions(context, cancion),
                          ),
                          onTap: () {
                            audioService.playSong(cancion['ruta'], cancion['titulo']);
                          },
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  color: Colors.red[900],
                  padding: EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(_isShuffleMode ? Icons.shuffle : Icons.shuffle_on_outlined, color: Colors.white),
                            onPressed: _toggleShuffleMode,
                          ),
                          IconButton(
                            icon: Icon(
                              _isLoopMode ? Icons.repeat : (_isSingleLoopMode ? Icons.repeat_one : Icons.repeat_outlined),
                              color: Colors.white,
                            ),
                            onPressed: _toggleLoopMode,
                          ),
                          IconButton(
                            icon: Icon(Icons.skip_previous, color: Colors.white),
                            onPressed: () => _playPreviousSong(audioService),
                          ),
                          IconButton(
                            icon: Icon(
                              audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: () {
                              audioService.isPlaying ? audioService.pauseSong() : audioService.resumeSong();
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.skip_next, color: Colors.white),
                            onPressed: () => _playNextSong(audioService),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  audioService.currentSong.isNotEmpty ? audioService.currentSong : 'No hay canción seleccionada',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  audioService.currentSong.isNotEmpty
                                      ? _canciones.firstWhere((cancion) => cancion['titulo'] == audioService.currentSong, orElse: () => {'artista': 'Desconocido'})['artista']
                                      : '',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}