import 'package:flutter/material.dart';

class PlayerScreen extends StatelessWidget {
  final String playlistName;

  const PlayerScreen({super.key, required this.playlistName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(playlistName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 100),
            Text(playlistName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.skip_previous), onPressed: () {}),
                IconButton(icon: const Icon(Icons.play_arrow, size: 50), onPressed: () {}),
                IconButton(icon: const Icon(Icons.skip_next), onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
