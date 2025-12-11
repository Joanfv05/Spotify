import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/music_api.dart';
import 'player_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MusicApi _api = MusicApi();
  List<Map<String, String>> playlists = [
    {'title': 'Canciones que te gustan', 'icon': 'heart'}
  ];
  List<Map<String, dynamic>> _canciones = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _cargarCanciones();
  }

  Future<void> _cargarCanciones() async {
    setState(() => loading = true);
    try {
      final results = await _api.buscarCanciones("eminem");
      setState(() {
        _canciones = results.map((song) => {
          'titulo': song['title']?.toString() ?? 'Sin título',
          'artista': song['artist']?['name']?.toString() ?? 'Desconocido',
          'preview': song['preview']?.toString() ?? '',
          'imagen': song['album']?['cover_medium']?.toString() ??
              song['album']?['cover_small']?.toString() ?? '',
          'id': song['id']?.toString() ?? UniqueKey().toString(),
          'album': song['album']?['title']?.toString() ?? 'Álbum desconocido',
        }).toList();
      });
    } catch (e) {
      print('Error cargando canciones: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  void _addNewPlaylist() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newPlaylistName = "";
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text("Crear nueva playlist", style: TextStyle(color: Colors.red)),
          content: TextField(
            style: TextStyle(color: Colors.white),
            onChanged: (value) => newPlaylistName = value,
            decoration: InputDecoration(
              hintText: "Nombre de la playlist",
              hintStyle: TextStyle(color: Colors.red[300]),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text("Cancelar", style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Crear", style: TextStyle(color: Colors.red)),
              onPressed: () {
                if (newPlaylistName.trim().isEmpty) return;
                setState(() {
                  playlists.add({'title': newPlaylistName, 'icon': 'note'});
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioService = Provider.of<AudioService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Música', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[900],
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => SearchScreen())
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.black,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tus Playlists',
                              style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold)
                          ),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.red),
                            onPressed: _addNewPlaylist,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, childAspectRatio: 1,
                        ),
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          return PlaylistTile(
                            title: playlists[index]['title']!,
                            iconType: playlists[index]['icon'] == 'heart'
                                ? Icons.favorite : Icons.music_note,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayerScreen(
                                  playlistName: playlists[index]['title']!,
                                  canciones: _canciones,
                                  initialTrack: _canciones.isNotEmpty ? _canciones[0] : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (audioService.currentSong != null)
              Container(
                color: Colors.red[900],
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(audioService.currentSongTitle,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(audioService.currentArtist,
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white),
                      onPressed: () {
                        if (audioService.isPlaying) {
                          audioService.pauseSong();
                        } else if (audioService.currentSong != null) {
                          audioService.resumeSong();
                        } else if (_canciones.isNotEmpty) {
                          audioService.playSongFromMap(_canciones[0]);
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
  }
}

class PlaylistTile extends StatelessWidget {
  final String title;
  final IconData iconType;
  final VoidCallback onTap;

  const PlaylistTile({Key? key, required this.title, required this.iconType, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.red[900],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconType, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            Text(title,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}