import 'package:flutter/material.dart';
import 'player_screen.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlist 1')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Canción 1'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlayerScreen(songTitle: 'Canción 1')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Canción 2'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlayerScreen(songTitle: 'Canción 2')),
              );
            },
          ),
        ],
      ),
    );
  }
}
