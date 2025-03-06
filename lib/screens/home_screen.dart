import 'package:flutter/material.dart';
import 'package:spotify/screens/playlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> playlists = [
    {
      'title': 'Canciones que te gustan',
      'imageUrl': 'assets/liked_songs.jpg',
    }
  ];

  void _addNewPlaylist() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newPlaylistName = "";
        return AlertDialog(
          title: Text("Crear nueva playlist"),
          content: TextField(
            onChanged: (value) {
              newPlaylistName = value;
            },
            decoration: InputDecoration(hintText: "Nombre de la playlist"),
          ),
          actions: [
            TextButton(
              child: Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Crear"),
              onPressed: () {
                setState(() {
                  playlists.add({
                    'title': newPlaylistName,
                    'imageUrl': 'assets/default_playlist.jpg',
                  });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Música'),
        backgroundColor: Colors.grey[900],
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tus Playlists',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.white),
                    onPressed: _addNewPlaylist,
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                ),
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  return PlaylistTile(
                    title: playlists[index]['title']!,
                    imageUrl: playlists[index]['imageUrl']!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaylistScreen(
                            playlistName: playlists[index]['title']!,
                          ),
                        ),
                      );
                    },
                  );
                },
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
  final String imageUrl;
  final VoidCallback onTap;

  const PlaylistTile({
    Key? key,
    required this.title,
    required this.imageUrl,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.grey[900],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}