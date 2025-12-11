import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import 'queue_screen.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistName;
  final List<Map<String, dynamic>> canciones;

  const PlaylistScreen({Key? key, required this.playlistName, required this.canciones}) : super(key: key);

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
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
                icon: Icon(Icons.shuffle, color: audioService.isShuffleMode ? Colors.white : Colors.grey[300]),
                onPressed: () => audioService.toggleShuffleMode(),
              ),
              IconButton(
                icon: Icon(Icons.repeat, color: audioService.isRepeatMode ? Colors.white : Colors.grey[300]),
                onPressed: () => audioService.toggleRepeatMode(),
              ),
              IconButton(
                icon: Icon(Icons.queue_music),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => QueueScreen())),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: widget.canciones.isEmpty
                        ? Center(
                        child: Text('No hay canciones',
                            style: TextStyle(color: Colors.grey[500], fontSize: 18))
                    )
                        : ListView.builder(
                      itemCount: widget.canciones.length,
                      itemBuilder: (context, index) {
                        final cancion = widget.canciones[index];
                        final isCurrent = audioService.isCurrentSong(cancion);
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              cancion['imagen']?.toString() ?? '',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[800],
                                  child: Icon(Icons.music_note, color: Colors.grey[600]),
                                );
                              },
                            ),
                          ),
                          title: Text(
                            cancion['titulo']?.toString() ?? 'Sin título',
                            style: TextStyle(
                              color: isCurrent ? Colors.red : Colors.white,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            cancion['artista']?.toString() ?? 'Desconocido',
                            style: TextStyle(
                              color: isCurrent ? Colors.red[200] : Colors.grey[400],
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.more_vert, color: Colors.white),
                            onPressed: () => _showSongOptions(context, cancion, audioService),
                          ),
                          onTap: () => audioService.playSongFromMap(cancion),
                        );
                      },
                    ),
                  ),
                ),
                if (audioService.currentSong != null)
                  Container(
                    color: Colors.red[900],
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: Icon(Icons.skip_previous, color: Colors.white),
                              onPressed: audioService.hasPreviousSong ? () => audioService.playPreviousSong() : null,
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
                                } else if (audioService.currentSong != null) {
                                  audioService.resumeSong();
                                } else if (widget.canciones.isNotEmpty) {
                                  audioService.playSongFromMap(widget.canciones[0]);
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.skip_next, color: Colors.white),
                              onPressed: audioService.hasNextSong ? () => audioService.playNextSong() : null,
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
                                    audioService.currentSongTitle,
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    audioService.currentArtist,
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

  void _showSongOptions(BuildContext context, Map<String, dynamic> song, AudioService audioService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.play_arrow, color: Colors.white),
                  title: Text('Reproducir ahora', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    audioService.playSongFromMap(song);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.playlist_add, color: Colors.white),
                  title: Text('Añadir a la cola', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    audioService.addToQueue(song);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red,
                        content: Text('Añadido a la cola'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.queue_music, color: Colors.white),
                  title: Text('Reproducir siguiente', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    audioService.insertNextInQueue(song);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red,
                        content: Text('Añadido como siguiente'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}