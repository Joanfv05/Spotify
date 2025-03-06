import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistName;

  const PlaylistScreen({super.key, required this.playlistName});

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isPaused = false;
  List<Map<String, dynamic>> _canciones = [];
  String _cancionActual = 'Ninguna';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    cargarCanciones();
  }

  Future<void> cargarCanciones() async {
    try {
      String jsonString = await rootBundle.loadString('assets/canciones.json');
      List<dynamic> jsonList = json.decode(jsonString);
      setState(() {
        _canciones = List<Map<String, dynamic>>.from(jsonList);
      });
    } catch (e) {
      print("Error al cargar el archivo JSON: $e");
    }
  }

  Future<void> reproducirCancion(String ruta, String titulo) async {
    try {
      await _audioPlayer.setFilePath(ruta);
      _audioPlayer.play();
      setState(() {
        _isPlaying = true;
        _isPaused = false;
        _cancionActual = titulo;
      });
    } catch (e) {
      print("Error al reproducir: $e");
    }
  }

  Future<void> pausarCancion() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
      _isPaused = true;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistName),
        backgroundColor: Colors.grey[900],
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _canciones.length,
                itemBuilder: (context, index) {
                  var cancion = _canciones[index];
                  return ListTile(
                    leading: const Icon(Icons.music_note, color: Colors.white),
                    title: Text(
                      cancion['titulo'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      cancion['artista'],
                      style: const TextStyle(color: Colors.white70),
                    ),
                    onTap: () {
                      reproducirCancion(cancion['ruta'], cancion['titulo']);
                    },
                  );
                },
              ),
            ),
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey[900],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Reproduciendo: $_cancionActual',
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (_isPlaying) {
                          pausarCancion();
                        } else if (_isPaused) {
                          _audioPlayer.play();
                          setState(() {
                            _isPlaying = true;
                            _isPaused = false;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}