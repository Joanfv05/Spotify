import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../audio_service.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistName;

  const PlaylistScreen({Key? key, required this.playlistName}) : super(key: key);

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<Map<String, dynamic>> _canciones = [];

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

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audioService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.playlistName, style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red[900],
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
                  child: Row(
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
                                  ? _canciones.firstWhere(
                                    (cancion) => cancion['titulo'] == audioService.currentSong,
                                orElse: () => {'artista': 'Desconocido'},
                              )['artista']
                                  : '',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          if (audioService.isPlaying) {
                            audioService.pauseSong();
                          } else {
                            audioService.resumeSong();
                          }
                        },
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